"""Analises complementares da revisao critica (somente leitura, so biblioteca padrao).

Le a trusted versionada (parte-1/dados/trusted/pedidos_entrega.csv) e mede, para o mesmo
periodo da pergunta (compras de 2017-01-01 a 2018-08-31):
  1. intervalo de confianca de 95% (Wilson) da taxa de atraso de cada UF;
  2. prazo prometido x prazo real por UF (a taxa mede promessa cumprida, nao velocidade);
  3. sensibilidade a exclusao dos pedidos nao entregues (promessas vencidas sem entrega);
  4. concentracao temporal dos atrasos (meses de pico).
Nao altera a metodologia nem os resultados oficiais. Grava exploracao/saida/analise_revisao.json.

Uso (na raiz do projeto): python exploracao/analise_revisao.py
"""
import csv
import json
import math
from collections import Counter, defaultdict
from datetime import date, datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
TRUSTED = RAIZ / "parte-1" / "dados" / "trusted" / "pedidos_entrega.csv"
SAIDA = Path(__file__).resolve().parent / "saida" / "analise_revisao.json"
INICIO, FIM = "2017-01-01 00:00:00", "2018-09-01 00:00:00"
# Ultima data observada na base (compra mais recente e entrega mais recente: 2018-10-17).
CORTE = date(2018, 10, 17)
EM_ABERTO_LOGISTICA = {"shipped", "invoiced", "processing", "approved", "created"}


def wilson(x, n, z=1.96):
    p = x / n
    centro = (p + z * z / (2 * n)) / (1 + z * z / n)
    meia = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return round(100 * (centro - meia), 2), round(100 * (centro + meia), 2)


def mediana(valores):
    v = sorted(valores)
    return v[len(v) // 2] if v else None


def main():
    with open(TRUSTED, encoding="utf-8", newline="") as f:
        linhas = [l for l in csv.DictReader(f) if INICIO <= l["data_hora_compra"] < FIM]

    eleg, atras = Counter(), Counter()
    prometido, real = defaultdict(list), defaultdict(list)
    vencidos_logistica, vencidos_todos = Counter(), Counter()
    status_vencidos = Counter()
    atras_mes = defaultdict(Counter)
    for l in linhas:
        uf = l["uf_cliente"]
        compra = datetime.strptime(l["data_hora_compra"], "%Y-%m-%d %H:%M:%S").date()
        prevista = date.fromisoformat(l["data_prevista_entrega"])
        if l["elegivel"] == "true":
            entrega = datetime.strptime(l["data_hora_entrega"], "%Y-%m-%d %H:%M:%S").date()
            eleg[uf] += 1
            prometido[uf].append((prevista - compra).days)
            real[uf].append((entrega - compra).days)
            if l["atrasado"] == "true":
                atras[uf] += 1
                atras_mes[uf][l["data_hora_compra"][:7]] += 1
        elif prevista < CORTE:
            status_vencidos[l["status_pedido"]] += 1
            vencidos_todos[uf] += 1
            if l["status_pedido"] in EM_ABERTO_LOGISTICA:
                vencidos_logistica[uf] += 1

    por_uf = {}
    for uf in sorted(eleg):
        n, x = eleg[uf], atras[uf]
        vl, vt = vencidos_logistica[uf], vencidos_todos[uf]
        por_uf[uf] = {
            "elegiveis": n,
            "atrasados": x,
            "taxa_pct": round(100 * x / n, 2),
            "ic95_wilson_pct": wilson(x, n),
            "prazo_prometido_medio_dias": round(sum(prometido[uf]) / n, 1),
            "prazo_real_medio_dias": round(sum(real[uf]) / n, 1),
            "prazo_real_mediano_dias": mediana(real[uf]),
            "vencidos_sem_entrega_logistica": vl,
            "taxa_com_vencidos_logistica_pct": round(100 * (x + vl) / (n + vl), 2),
            "vencidos_sem_entrega_todos": vt,
            "taxa_com_todos_vencidos_pct": round(100 * (x + vt) / (n + vt), 2),
            "atrasados_em_2017_11_2018_02_2018_03": sum(atras_mes[uf][m] for m in ("2017-11", "2018-02", "2018-03")),
        }

    def ranking(chave, n=5):
        return [uf for uf, _ in sorted(por_uf.items(), key=lambda kv: -kv[1][chave])][:n]

    resultado = {
        "periodo": [INICIO, FIM],
        "data_de_corte_da_base": CORTE.isoformat(),
        "pedidos_no_periodo": len(linhas),
        "elegiveis": sum(eleg.values()),
        "atrasados": sum(atras.values()),
        "nao_entregues_com_prazo_vencido_por_status": dict(status_vencidos.most_common()),
        "ranking_por_atrasados": ranking("atrasados"),
        "ranking_por_taxa": ranking("taxa_pct"),
        "ranking_por_taxa_com_vencidos_logistica": ranking("taxa_com_vencidos_logistica_pct"),
        "ranking_por_taxa_com_todos_vencidos": ranking("taxa_com_todos_vencidos_pct"),
        "por_uf": por_uf,
    }
    SAIDA.parent.mkdir(exist_ok=True)
    SAIDA.write_text(json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    print(f"periodo {INICIO[:10]} a {FIM[:10]} (exclusivo): {len(linhas)} pedidos, "
          f"{resultado['elegiveis']} elegiveis, {resultado['atrasados']} atrasados")
    print("nao entregues com prazo vencido ate", CORTE, "por status:", resultado["nao_entregues_com_prazo_vencido_por_status"])
    print("UF  elegiv atras  taxa%  IC95%(Wilson)    prometido real(med) | +venc.logist taxa% | +todos venc. taxa% | atras.picos")
    for uf, r in sorted(por_uf.items(), key=lambda kv: -kv[1]["atrasados"]):
        print(f"{uf}  {r['elegiveis']:6} {r['atrasados']:5} {r['taxa_pct']:6.2f}  "
              f"[{r['ic95_wilson_pct'][0]:5.2f}, {r['ic95_wilson_pct'][1]:5.2f}]  "
              f"{r['prazo_prometido_medio_dias']:6.1f} {r['prazo_real_medio_dias']:5.1f}({r['prazo_real_mediano_dias']:3}) | "
              f"{r['vencidos_sem_entrega_logistica']:4} {r['taxa_com_vencidos_logistica_pct']:6.2f} | "
              f"{r['vencidos_sem_entrega_todos']:4} {r['taxa_com_todos_vencidos_pct']:6.2f} | "
              f"{r['atrasados_em_2017_11_2018_02_2018_03']:4}")
    for chave in ("ranking_por_atrasados", "ranking_por_taxa", "ranking_por_taxa_com_vencidos_logistica",
                  "ranking_por_taxa_com_todos_vencidos"):
        print(chave, resultado[chave])
    print(f"gravado em {SAIDA.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
