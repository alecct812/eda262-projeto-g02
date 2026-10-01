"""Analise exploratoria inicial do dataset Olist (somente leitura).

Le os CSVs de dataset/archive/ sem altera-los e grava um perfil em
exploracao/saida/perfil_olist.json. Usa apenas a biblioteca padrao.

Uso (na raiz do projeto):  python exploracao/eda_olist.py
"""
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DADOS = RAIZ / "dataset" / "archive"
SAIDA = Path(__file__).resolve().parent / "saida"

csv.field_size_limit(sys.maxsize if sys.maxsize < 2**31 else 2**31 - 1)

ARQUIVOS = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

RE_INT = re.compile(r"^-?\d+$")
RE_FLOAT = re.compile(r"^-?\d+\.\d+$")
RE_TS = re.compile(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$")
FMT_TS = "%Y-%m-%d %H:%M:%S"


def sha256(caminho):
    h = hashlib.sha256()
    with open(caminho, "rb") as f:
        for bloco in iter(lambda: f.read(1 << 20), b""):
            h.update(bloco)
    return h.hexdigest()


def ler(nome):
    """Retorna (cabecalho, linhas, linhas_fisicas) lendo como UTF-8 (BOM removido)."""
    caminho = DADOS / ARQUIVOS[nome]
    with open(caminho, encoding="utf-8-sig", newline="") as f:
        leitor = csv.reader(f)
        cab = next(leitor)
        linhas = list(leitor)
    with open(caminho, "rb") as f:
        fisicas = sum(1 for _ in f)
    return cab, linhas, fisicas


def tipo_valor(v):
    if RE_INT.match(v):
        return "int"
    if RE_FLOAT.match(v):
        return "float"
    if RE_TS.match(v):
        return "timestamp"
    return "string"


def perfil_colunas(cab, linhas):
    perfil = {}
    for i, col in enumerate(cab):
        vals = [l[i] for l in linhas]
        vazios = sum(1 for v in vals if v == "")
        nao_vazios = [v for v in vals if v != ""]
        tipos = Counter(tipo_valor(v) for v in nao_vazios)
        distintos = len(set(nao_vazios))
        info = {
            "vazios": vazios,
            "pct_vazios": round(100 * vazios / len(vals), 3) if vals else 0,
            "distintos": distintos,
            "tipos_observados": dict(tipos),
        }
        dominante = tipos.most_common(1)[0][0] if tipos else None
        if dominante in ("int", "float"):
            nums = [float(v) for v in nao_vazios if tipo_valor(v) in ("int", "float")]
            info["min"], info["max"] = min(nums), max(nums)
            info["negativos"] = sum(1 for n in nums if n < 0)
            info["zeros"] = sum(1 for n in nums if n == 0)
        elif dominante == "timestamp":
            ts = sorted(v for v in nao_vazios if RE_TS.match(v))
            info["min"], info["max"] = ts[0], ts[-1]
        else:
            comp = [len(v) for v in nao_vazios]
            if comp:
                info["comprimento_min"], info["comprimento_max"] = min(comp), max(comp)
            if distintos <= 30:
                info["frequencias"] = dict(Counter(nao_vazios).most_common())
        perfil[col] = info
    return perfil


def unicidade(linhas, idxs):
    chaves = Counter(tuple(l[i] for i in idxs) for l in linhas)
    repetidas = {k: c for k, c in chaves.items() if c > 1}
    return {
        "linhas": len(linhas),
        "chaves_distintas": len(chaves),
        "chaves_repetidas": len(repetidas),
        "linhas_em_chaves_repetidas": sum(repetidas.values()),
    }


def integridade(filho, idx_f, pai, idx_p):
    chaves_pai = {l[idx_p] for l in pai}
    vals_f = [l[idx_f] for l in filho if l[idx_f] != ""]
    orfaos = [v for v in vals_f if v not in chaves_pai]
    return {
        "linhas_filho_com_chave": len(vals_f),
        "linhas_filho_orfas": len(orfaos),
        "chaves_orfas_distintas": len(set(orfaos)),
        "chaves_pai": len(chaves_pai),
        "chaves_pai_sem_filho": len(chaves_pai - set(vals_f)),
    }


def main():
    SAIDA.mkdir(exist_ok=True)
    tabelas, resultado = {}, {"arquivos": {}}

    for nome, arq in ARQUIVOS.items():
        cab, linhas, fisicas = ler(nome)
        tabelas[nome] = (cab, linhas)
        larguras = Counter(len(l) for l in linhas)
        resultado["arquivos"][nome] = {
            "arquivo": arq,
            "bytes": (DADOS / arq).stat().st_size,
            "sha256": sha256(DADOS / arq),
            "linhas_fisicas": fisicas,
            "registros": len(linhas),
            "registros_multilinha": fisicas - 1 - len(linhas),
            "colunas": cab,
            "larguras_de_registro": dict(larguras),
            "duplicatas_exatas": len(linhas) - len({tuple(l) for l in linhas}),
            "perfil": perfil_colunas(cab, linhas),
        }
        print(f"[ok] {nome}: {len(linhas)} registros")

    col = {n: {c: i for i, c in enumerate(t[0])} for n, t in tabelas.items()}
    L = {n: t[1] for n, t in tabelas.items()}

    # --- chaves -------------------------------------------------------------
    chaves = {
        "orders.order_id": ("orders", ["order_id"]),
        "customers.customer_id": ("customers", ["customer_id"]),
        "customers.customer_unique_id": ("customers", ["customer_unique_id"]),
        "order_items.(order_id,order_item_id)": ("order_items", ["order_id", "order_item_id"]),
        "order_payments.(order_id,payment_sequential)": ("order_payments", ["order_id", "payment_sequential"]),
        "order_reviews.review_id": ("order_reviews", ["review_id"]),
        "order_reviews.(review_id,order_id)": ("order_reviews", ["review_id", "order_id"]),
        "order_reviews.order_id": ("order_reviews", ["order_id"]),
        "products.product_id": ("products", ["product_id"]),
        "sellers.seller_id": ("sellers", ["seller_id"]),
        "category_translation.product_category_name": ("category_translation", ["product_category_name"]),
        "geolocation.zip_code_prefix": ("geolocation", ["geolocation_zip_code_prefix"]),
    }
    resultado["chaves"] = {
        k: unicidade(L[t], [col[t][c] for c in cs]) for k, (t, cs) in chaves.items()
    }

    # --- integridade referencial --------------------------------------------
    rels = {
        "orders.customer_id -> customers": ("orders", "customer_id", "customers", "customer_id"),
        "order_items.order_id -> orders": ("order_items", "order_id", "orders", "order_id"),
        "order_items.product_id -> products": ("order_items", "product_id", "products", "product_id"),
        "order_items.seller_id -> sellers": ("order_items", "seller_id", "sellers", "seller_id"),
        "order_payments.order_id -> orders": ("order_payments", "order_id", "orders", "order_id"),
        "order_reviews.order_id -> orders": ("order_reviews", "order_id", "orders", "order_id"),
        "products.category -> translation": ("products", "product_category_name", "category_translation", "product_category_name"),
        "customers.zip -> geolocation": ("customers", "customer_zip_code_prefix", "geolocation", "geolocation_zip_code_prefix"),
        "sellers.zip -> geolocation": ("sellers", "seller_zip_code_prefix", "geolocation", "geolocation_zip_code_prefix"),
    }
    resultado["integridade"] = {
        k: integridade(L[f], col[f][cf], L[p], col[p][cp]) for k, (f, cf, p, cp) in rels.items()
    }

    # --- pedidos: status, datas, sequencia, atraso --------------------------
    o, oc = L["orders"], col["orders"]
    datas = ["order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date",
             "order_delivered_customer_date", "order_estimated_delivery_date"]

    def dt(l, c):
        v = l[oc[c]]
        return datetime.strptime(v, FMT_TS) if v else None

    nulos_por_status = defaultdict(lambda: Counter())
    status = Counter()
    for l in o:
        s = l[oc["order_status"]]
        status[s] += 1
        for c in datas:
            if l[oc[c]] == "":
                nulos_por_status[s][c] += 1
    resultado["orders_status"] = dict(status.most_common())
    resultado["orders_nulos_por_status"] = {s: dict(c) for s, c in nulos_por_status.items()}

    seq = Counter()
    hora_estimada = Counter()
    for l in o:
        p, a, cr, d, e = (dt(l, c) for c in datas)
        hora_estimada[l[oc["order_estimated_delivery_date"]][11:]] += 1
        if a and a < p: seq["aprovacao_antes_da_compra"] += 1
        if cr and p and cr < p: seq["coleta_antes_da_compra"] += 1
        if cr and a and cr < a: seq["coleta_antes_da_aprovacao"] += 1
        if d and cr and d < cr: seq["entrega_antes_da_coleta"] += 1
        if d and d < p: seq["entrega_antes_da_compra"] += 1
        if e and e < p: seq["prevista_antes_da_compra"] += 1
        s = l[oc["order_status"]]
        if s == "delivered" and d is None: seq["delivered_sem_data_entrega"] += 1
        if s != "delivered" and d is not None: seq[f"nao_delivered_com_data_entrega({s})"] += 1
    resultado["orders_sequencia_datas"] = dict(seq)
    resultado["orders_hora_da_data_prevista"] = dict(hora_estimada.most_common(5))

    # cobertura temporal
    por_mes = Counter(l[oc["order_purchase_timestamp"]][:7] for l in o)
    resultado["orders_por_mes_compra"] = dict(sorted(por_mes.items()))
    entregues_por_mes = Counter(
        l[oc["order_purchase_timestamp"]][:7] for l in o if l[oc["order_status"]] == "delivered"
    )
    resultado["orders_delivered_por_mes_compra"] = dict(sorted(entregues_por_mes.items()))

    # atraso (definicao candidata: data da entrega > data prevista, comparando so a data)
    cust = {l[col["customers"]["customer_id"]]: l for l in L["customers"]}
    uf_idx = col["customers"]["customer_state"]
    eleg, atras, dias_atraso = Counter(), Counter(), []
    celula = Counter()
    atras_ts = 0
    for l in o:
        if l[oc["order_status"]] != "delivered":
            continue
        d, e = dt(l, "order_delivered_customer_date"), dt(l, "order_estimated_delivery_date")
        if d is None or e is None:
            continue
        c = cust.get(l[oc["customer_id"]])
        uf = c[uf_idx] if c else "?"
        eleg[uf] += 1
        celula[(uf, l[oc["order_purchase_timestamp"]][:7])] += 1
        if d > e:
            atras_ts += 1
        if d.date() > e.date():
            atras[uf] += 1
            dias_atraso.append((d.date() - e.date()).days)
    tot_e, tot_a = sum(eleg.values()), sum(atras.values())
    dias_atraso.sort()
    resultado["atraso_candidato"] = {
        "elegiveis": tot_e,
        "atrasados_por_data": tot_a,
        "taxa_pct": round(100 * tot_a / tot_e, 2),
        "atrasados_se_comparar_timestamp": atras_ts,
        "dias_atraso_mediana": dias_atraso[len(dias_atraso) // 2],
        "dias_atraso_p90": dias_atraso[int(len(dias_atraso) * 0.9)],
        "dias_atraso_max": dias_atraso[-1],
        "por_uf": {
            uf: {"elegiveis": eleg[uf], "atrasados": atras[uf],
                 "taxa_pct": round(100 * atras[uf] / eleg[uf], 2)}
            for uf, _ in eleg.most_common()
        },
    }
    # serie mensal da taxa de atraso e pedidos ainda em aberto (efeito de borda)
    mes_e, mes_a, abertos = Counter(), Counter(), Counter()
    for l in o:
        mes = l[oc["order_purchase_timestamp"]][:7]
        s = l[oc["order_status"]]
        if s in ("shipped", "invoiced", "processing", "created", "approved"):
            abertos[mes] += 1
        d, e = dt(l, "order_delivered_customer_date"), dt(l, "order_estimated_delivery_date")
        if s == "delivered" and d and e:
            mes_e[mes] += 1
            if d.date() > e.date():
                mes_a[mes] += 1
    resultado["atraso_por_mes_compra"] = {
        m: {"elegiveis": mes_e[m], "atrasados": mes_a[m],
            "taxa_pct": round(100 * mes_a[m] / mes_e[m], 2), "em_aberto": abertos[m]}
        for m in sorted(mes_e)
    }
    resultado["em_aberto_por_mes_compra"] = dict(sorted(abertos.items()))

    tam = sorted(celula.values())
    resultado["celulas_uf_mes"] = {
        "celulas": len(tam),
        "min": tam[0], "mediana": tam[len(tam) // 2], "max": tam[-1],
        "abaixo_de_30": sum(1 for t in tam if t < 30),
        "abaixo_de_100": sum(1 for t in tam if t < 100),
    }

    # --- clientes e geografia ------------------------------------------------
    cu, cc = L["customers"], col["customers"]
    resultado["customers_por_uf"] = dict(Counter(l[cc["customer_state"]] for l in cu).most_common())
    compras_por_pessoa = Counter(l[cc["customer_unique_id"]] for l in cu)
    resultado["customers_pedidos_por_pessoa"] = dict(sorted(Counter(compras_por_pessoa.values()).items()))
    zips = [l[cc["customer_zip_code_prefix"]] for l in cu]
    resultado["customers_zip_comprimentos"] = dict(Counter(len(z) for z in zips))
    # cidade com/sem acento e variacoes de grafia
    cidades = [l[cc["customer_city"]] for l in cu]
    resultado["customers_cidades_com_nao_ascii"] = sum(1 for c in cidades if not c.isascii())
    geo, gc = L["geolocation"], col["geolocation"]
    gcid = [l[gc["geolocation_city"]] for l in geo]
    resultado["geolocation_cidades_com_nao_ascii"] = sum(1 for c in gcid if not c.isascii())
    lat_fora = sum(1 for l in geo if not (-34 <= float(l[gc["geolocation_lat"]]) <= 6))
    lng_fora = sum(1 for l in geo if not (-74 <= float(l[gc["geolocation_lng"]]) <= -34))
    resultado["geolocation_fora_do_brasil_aprox"] = {"lat": lat_fora, "lng": lng_fora}

    # --- itens / pagamentos: cardinalidade e consistencia --------------------
    it, ic = L["order_items"], col["order_items"]
    itens_por_pedido = Counter(l[ic["order_id"]] for l in it)
    resultado["itens_por_pedido"] = dict(sorted(Counter(itens_por_pedido.values()).items()))
    vend_por_pedido = defaultdict(set)
    for l in it:
        vend_por_pedido[l[ic["order_id"]]].add(l[ic["seller_id"]])
    resultado["pedidos_multivendedor"] = sum(1 for s in vend_por_pedido.values() if len(s) > 1)
    pg, pc = L["order_payments"], col["order_payments"]
    pag_por_pedido = Counter(l[pc["order_id"]] for l in pg)
    resultado["pagamentos_por_pedido"] = dict(sorted(Counter(pag_por_pedido.values()).items()))
    soma_itens = defaultdict(float)
    for l in it:
        soma_itens[l[ic["order_id"]]] += float(l[ic["price"]]) + float(l[ic["freight_value"]])
    soma_pag = defaultdict(float)
    for l in pg:
        soma_pag[l[pc["order_id"]]] += float(l[pc["payment_value"]])
    comuns = set(soma_itens) & set(soma_pag)
    difs = [abs(soma_itens[k] - soma_pag[k]) for k in comuns]
    resultado["itens_vs_pagamentos"] = {
        "pedidos_comparados": len(comuns),
        "diferenca_maior_que_1_real": sum(1 for d in difs if d > 1),
        "pedidos_com_itens_sem_pagamento": len(set(soma_itens) - set(soma_pag)),
        "pedidos_com_pagamento_sem_itens": len(set(soma_pag) - set(soma_itens)),
    }
    pedidos_sem_itens = Counter(
        l[oc["order_status"]] for l in o if l[oc["order_id"]] not in itens_por_pedido
    )
    resultado["pedidos_sem_itens_por_status"] = dict(pedidos_sem_itens)

    # --- aspas inconsistentes no arquivo bruto --------------------------------
    aspas = {}
    for nome in ("orders", "customers", "order_items"):
        with open(DADOS / ARQUIVOS[nome], encoding="utf-8-sig") as f:
            next(f)
            prim = [ln.split(",", 1)[0] for ln in f]
        aspas[nome] = {
            "primeiro_campo_com_aspas": sum(1 for p in prim if p.startswith('"')),
            "primeiro_campo_sem_aspas": sum(1 for p in prim if not p.startswith('"')),
        }
    resultado["aspas_inconsistentes"] = aspas

    destino = SAIDA / "perfil_olist.json"
    destino.write_text(json.dumps(resultado, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[ok] perfil gravado em {destino.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
