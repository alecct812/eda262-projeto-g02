"""Prepara a tabela trusted `pedidos_entrega` a partir dos CSVs brutos da Olist.

Grão: uma linha por pedido (chave id_pedido). Lê parte-1/dados/raw/ e grava
parte-1/dados/trusted/pedidos_entrega.csv e manifesto.json. Apenas biblioteca padrão.

Uso (de qualquer diretório): python parte-1/preparo/prepara_trusted.py
"""
import csv
import hashlib
import json
import re
from collections import Counter
from datetime import datetime
from pathlib import Path

PARTE1 = Path(__file__).resolve().parent.parent
RAW = PARTE1 / "dados" / "raw"
TRUSTED = PARTE1 / "dados" / "trusted"
ARQ_PEDIDOS = RAW / "olist_orders_dataset.csv"
ARQ_CLIENTES = RAW / "olist_customers_dataset.csv"
ARQ_SAIDA = TRUSTED / "pedidos_entrega.csv"
ARQ_MANIFESTO = TRUSTED / "manifesto.json"

# Ordem idêntica à das colunas declaradas na tabela Glue (modules/lake/main.tf).
COLUNAS = [
    "id_pedido", "uf_cliente", "status_pedido", "data_hora_compra", "data_prevista_entrega",
    "data_hora_entrega", "elegivel", "atrasado", "dias_atraso", "motivo_exclusao",
]
UFS = {"AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA",
       "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"}
STATUS = {"delivered", "shipped", "canceled", "unavailable", "invoiced", "processing",
          "created", "approved"}
RE_ID = re.compile(r"^[0-9a-f]{32}$")
FMT_TS = "%Y-%m-%d %H:%M:%S"
# Período da pergunta de negócio: [início, fim). Mesmo filtro de consulta/pergunta.sql.
PERIODO = ("2017-01-01 00:00:00", "2018-09-01 00:00:00")


class DadoInvalido(ValueError):
    """Entrada fora do padrão: o preparo para em vez de descartar linhas em silêncio."""


def ler_csv(caminho):
    with open(caminho, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def parse_ts(texto, campo):
    if texto == "":
        return None
    try:
        return datetime.strptime(texto, FMT_TS)
    except ValueError as erro:
        raise DadoInvalido(f"{campo}: data invalida {texto!r}") from erro


def classifica(status, entrega, prevista):
    """Retorna (elegivel, atrasado, dias_atraso, motivo_exclusao).

    O atraso compara dias: entrega no próprio dia previsto, a qualquer hora, é pontual.
    """
    if status != "delivered":
        return False, None, None, "status_nao_entregue"
    if entrega is None:
        return False, None, None, "entregue_sem_data"
    dias = (entrega.date() - prevista).days
    return True, dias > 0, dias, None


def _mapa_uf(clientes):
    uf_por_cliente = {}
    for c in clientes:
        cid = c["customer_id"].strip()
        if not RE_ID.match(cid):
            raise DadoInvalido(f"customer_id invalido {cid!r}")
        if cid in uf_por_cliente:
            raise DadoInvalido(f"customer_id duplicado {cid}")
        uf = c["customer_state"].strip().upper()
        if uf not in UFS:
            raise DadoInvalido(f"UF invalida {uf!r} no cliente {cid}")
        uf_por_cliente[cid] = uf
    return uf_por_cliente


def _anomalias(contagens, status, compra, aprovacao, coleta, entrega):
    """Inconsistências diagnosticadas e contadas, sem excluir o pedido do indicador."""
    if coleta and coleta < compra:
        contagens["anomalia_coleta_antes_da_compra"] += 1
    if coleta and aprovacao and coleta < aprovacao:
        contagens["anomalia_coleta_antes_da_aprovacao"] += 1
    if entrega and coleta and entrega < coleta:
        contagens["anomalia_entrega_antes_da_coleta"] += 1
    if entrega and entrega < compra:
        contagens["anomalia_entrega_antes_da_compra"] += 1
    if status != "delivered" and entrega is not None:
        contagens["anomalia_nao_entregue_com_data_de_entrega"] += 1
    if status == "delivered" and aprovacao is None:
        contagens["anomalia_entregue_sem_aprovacao"] += 1
    if status == "delivered" and coleta is None:
        contagens["anomalia_entregue_sem_coleta"] += 1


def transforma(pedidos, clientes):
    """Aplica as regras e devolve (linhas ordenadas por id_pedido, contagens)."""
    uf_por_cliente = _mapa_uf(clientes)
    contagens = Counter()
    vistos = set()
    linhas = []
    for p in pedidos:
        oid = p["order_id"].strip()
        if not RE_ID.match(oid):
            raise DadoInvalido(f"order_id invalido {oid!r}")
        if oid in vistos:
            raise DadoInvalido(f"order_id duplicado {oid}")
        vistos.add(oid)
        cid = p["customer_id"].strip()
        if cid not in uf_por_cliente:
            raise DadoInvalido(f"pedido {oid} sem cliente correspondente")
        status = p["order_status"].strip()
        if status not in STATUS:
            raise DadoInvalido(f"status desconhecido {status!r} no pedido {oid}")
        compra = parse_ts(p["order_purchase_timestamp"].strip(), "order_purchase_timestamp")
        aprovacao = parse_ts(p["order_approved_at"].strip(), "order_approved_at")
        coleta = parse_ts(p["order_delivered_carrier_date"].strip(), "order_delivered_carrier_date")
        entrega = parse_ts(p["order_delivered_customer_date"].strip(), "order_delivered_customer_date")
        prevista = parse_ts(p["order_estimated_delivery_date"].strip(), "order_estimated_delivery_date")
        if compra is None or prevista is None:
            raise DadoInvalido(f"pedido {oid} sem data de compra ou data prevista")
        if prevista.time() != datetime.min.time():
            contagens["prevista_com_hora_diferente_de_zero"] += 1

        elegivel, atrasado, dias, motivo = classifica(status, entrega, prevista.date())
        contagens["linhas"] += 1
        contagens["elegiveis" if elegivel else f"excluido_{motivo}"] += 1
        if atrasado:
            contagens["atrasados"] += 1
        _anomalias(contagens, status, compra, aprovacao, coleta, entrega)

        linhas.append({
            "id_pedido": oid,
            "uf_cliente": uf_por_cliente[cid],
            "status_pedido": status,
            "data_hora_compra": compra.strftime(FMT_TS),
            "data_prevista_entrega": prevista.date().isoformat(),
            "data_hora_entrega": entrega.strftime(FMT_TS) if entrega else "",
            "elegivel": "true" if elegivel else "false",
            "atrasado": "" if atrasado is None else ("true" if atrasado else "false"),
            "dias_atraso": "" if dias is None else str(dias),
            "motivo_exclusao": motivo or "",
        })
    linhas.sort(key=lambda l: l["id_pedido"])
    return linhas, dict(sorted(contagens.items()))


def serializa_csv(linhas):
    """CSV com cabeçalho, separador vírgula, sem aspas, LF. Nulo é campo vazio."""
    for l in linhas:
        for c in COLUNAS:
            if any(ch in l[c] for ch in ',"\r\n'):
                raise DadoInvalido(f"campo {c} com caractere reservado no pedido {l['id_pedido']}")
    corpo = [",".join(COLUNAS)] + [",".join(l[c] for c in COLUNAS) for l in linhas]
    return ("\n".join(corpo) + "\n").encode("utf-8")


def tamanho_jsonl(linhas):
    """Bytes que as mesmas linhas ocupariam em JSON Lines (para a decisão de formato)."""
    total = 0
    for l in linhas:
        obj = {c: (l[c] if l[c] != "" else None) for c in COLUNAS}
        for c in ("elegivel", "atrasado"):
            if obj[c] is not None:
                obj[c] = obj[c] == "true"
        if obj["dias_atraso"] is not None:
            obj["dias_atraso"] = int(obj["dias_atraso"])
        total += len(json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")) + 1
    return total


def resumo_pergunta(linhas):
    """Cálculo local da pergunta (por UF, elegíveis no período) para conferir o Athena."""
    inicio, fim = PERIODO
    por_uf = {}
    for l in linhas:
        if l["elegivel"] != "true" or not (inicio <= l["data_hora_compra"] < fim):
            continue
        r = por_uf.setdefault(l["uf_cliente"], {"elegiveis": 0, "atrasados": 0})
        r["elegiveis"] += 1
        r["atrasados"] += l["atrasado"] == "true"
    return {
        "periodo": [inicio, fim],
        "ufs": len(por_uf),
        "elegiveis": sum(r["elegiveis"] for r in por_uf.values()),
        "atrasados": sum(r["atrasados"] for r in por_uf.values()),
        "por_uf": dict(sorted(por_uf.items())),
    }


def _aspas_primeiro_campo(caminho):
    com = sem = 0
    with open(caminho, encoding="utf-8-sig") as f:
        next(f)
        for linha in f:
            if linha.startswith('"'):
                com += 1
            else:
                sem += 1
    return {"com_aspas": com, "sem_aspas": sem}


def _sha256(dados):
    return hashlib.sha256(dados).hexdigest()


def main():
    pedidos = ler_csv(ARQ_PEDIDOS)
    clientes = ler_csv(ARQ_CLIENTES)
    linhas, contagens = transforma(pedidos, clientes)
    dados = serializa_csv(linhas)
    TRUSTED.mkdir(parents=True, exist_ok=True)
    ARQ_SAIDA.write_bytes(dados)
    manifesto = {
        "entradas": {
            ARQ_PEDIDOS.name: {"linhas": len(pedidos), "sha256": _sha256(ARQ_PEDIDOS.read_bytes())},
            ARQ_CLIENTES.name: {"linhas": len(clientes), "sha256": _sha256(ARQ_CLIENTES.read_bytes())},
        },
        "order_id_no_bruto": _aspas_primeiro_campo(ARQ_PEDIDOS),
        "contagens": contagens,
        "saida": {
            "arquivo": ARQ_SAIDA.name,
            "linhas": len(linhas),
            "bytes": len(dados),
            "sha256": _sha256(dados),
            "bytes_equivalente_jsonl": tamanho_jsonl(linhas),
        },
        "pergunta_referencia": resumo_pergunta(linhas),
    }
    ARQ_MANIFESTO.write_text(json.dumps(manifesto, ensure_ascii=False, indent=2) + "\n",
                             encoding="utf-8", newline="\n")
    print(f"trusted: {len(linhas)} linhas, {len(dados)} bytes, sha256 {manifesto['saida']['sha256']}")
    print(f"elegiveis={contagens['elegiveis']} atrasados={contagens['atrasados']}")


if __name__ == "__main__":
    main()
