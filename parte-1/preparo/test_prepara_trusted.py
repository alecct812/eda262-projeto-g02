"""Testes do preparo da trusted. Rodar da raiz: python -m unittest discover -s parte-1/preparo -v"""
import hashlib
import subprocess
import sys
import tempfile
import unittest
from datetime import date, datetime
from pathlib import Path

import prepara_trusted as pt

A = "a" * 32
B = "b" * 32


def pedido(oid=A, cid=B, status="delivered", compra="2017-05-01 10:00:00",
           aprovacao="2017-05-01 11:00:00", coleta="2017-05-02 09:00:00",
           entrega="2017-05-10 15:00:00", prevista="2017-05-10 00:00:00"):
    return {"order_id": oid, "customer_id": cid, "order_status": status,
            "order_purchase_timestamp": compra, "order_approved_at": aprovacao,
            "order_delivered_carrier_date": coleta, "order_delivered_customer_date": entrega,
            "order_estimated_delivery_date": prevista}


def cliente(cid=B, uf="SP"):
    return {"customer_id": cid, "customer_unique_id": "c" * 32,
            "customer_zip_code_prefix": "01001", "customer_city": "sao paulo",
            "customer_state": uf}


class TestClassifica(unittest.TestCase):
    def test_entrega_no_dia_previsto_a_tarde_e_pontual(self):
        self.assertEqual(pt.classifica("delivered", datetime(2017, 5, 10, 15, 0, 0), date(2017, 5, 10)),
                         (True, False, 0, None))

    def test_entrega_no_dia_seguinte_e_atraso(self):
        self.assertEqual(pt.classifica("delivered", datetime(2017, 5, 11, 0, 0, 1), date(2017, 5, 10)),
                         (True, True, 1, None))

    def test_entrega_antecipada_tem_dias_negativos(self):
        self.assertEqual(pt.classifica("delivered", datetime(2017, 5, 7, 9, 0, 0), date(2017, 5, 10)),
                         (True, False, -3, None))

    def test_status_nao_entregue_e_excluido(self):
        self.assertEqual(pt.classifica("shipped", None, date(2017, 5, 10)),
                         (False, None, None, "status_nao_entregue"))

    def test_cancelado_com_data_de_entrega_continua_excluido(self):
        self.assertEqual(pt.classifica("canceled", datetime(2017, 5, 9), date(2017, 5, 10)),
                         (False, None, None, "status_nao_entregue"))

    def test_entregue_sem_data_e_excluido(self):
        self.assertEqual(pt.classifica("delivered", None, date(2017, 5, 10)),
                         (False, None, None, "entregue_sem_data"))


class TestTransforma(unittest.TestCase):
    def test_linha_completa(self):
        linhas, contagens = pt.transforma([pedido()], [cliente()])
        self.assertEqual(linhas, [{
            "id_pedido": A, "uf_cliente": "SP", "status_pedido": "delivered",
            "data_hora_compra": "2017-05-01 10:00:00", "data_prevista_entrega": "2017-05-10",
            "data_hora_entrega": "2017-05-10 15:00:00", "elegivel": "true", "atrasado": "false",
            "dias_atraso": "0", "motivo_exclusao": "",
        }])
        self.assertEqual(contagens["elegiveis"], 1)

    def test_nao_elegivel_tem_campos_derivados_vazios(self):
        linhas, contagens = pt.transforma([pedido(status="canceled", entrega="")], [cliente()])
        l = linhas[0]
        self.assertEqual((l["elegivel"], l["atrasado"], l["dias_atraso"], l["motivo_exclusao"], l["data_hora_entrega"]),
                         ("false", "", "", "status_nao_entregue", ""))
        self.assertEqual(contagens["excluido_status_nao_entregue"], 1)

    def test_leitura_com_e_sem_aspas(self):
        texto = ('"order_id","customer_id"\n'
                 f'"{A}",{B}\n'
                 f'{B},"{A}"\n')
        with tempfile.TemporaryDirectory() as d:
            caminho = Path(d) / "x.csv"
            caminho.write_text(texto, encoding="utf-8")
            linhas = pt.ler_csv(caminho)
        self.assertEqual([(l["order_id"], l["customer_id"]) for l in linhas], [(A, B), (B, A)])

    def test_pedido_sem_cliente_falha(self):
        with self.assertRaises(pt.DadoInvalido):
            pt.transforma([pedido(cid="d" * 32)], [cliente()])

    def test_order_id_duplicado_falha(self):
        with self.assertRaises(pt.DadoInvalido):
            pt.transforma([pedido(), pedido()], [cliente()])

    def test_order_id_fora_do_padrao_falha(self):
        with self.assertRaises(pt.DadoInvalido):
            pt.transforma([pedido(oid="xyz")], [cliente()])

    def test_uf_invalida_falha(self):
        with self.assertRaises(pt.DadoInvalido):
            pt.transforma([pedido()], [cliente(uf="XX")])

    def test_data_invalida_falha(self):
        with self.assertRaises(pt.DadoInvalido):
            pt.transforma([pedido(entrega="10/05/2017")], [cliente()])

    def test_saida_ordenada_por_id(self):
        linhas, _ = pt.transforma([pedido(oid=B, cid=A), pedido(oid=A, cid=B)], [cliente(A), cliente(B)])
        self.assertEqual([l["id_pedido"] for l in linhas], [A, B])


class TestSerializa(unittest.TestCase):
    def test_csv_sem_aspas_com_lf_e_cabecalho(self):
        linhas, _ = pt.transforma([pedido()], [cliente()])
        dados = pt.serializa_csv(linhas)
        self.assertNotIn(b'"', dados)
        self.assertNotIn(b"\r", dados)
        self.assertEqual(dados.split(b"\n")[0].decode(), ",".join(pt.COLUNAS))

    def test_campo_com_virgula_falha(self):
        linhas, _ = pt.transforma([pedido()], [cliente()])
        linhas[0]["status_pedido"] = "a,b"
        with self.assertRaises(pt.DadoInvalido):
            pt.serializa_csv(linhas)


class TestPontaAPonta(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pedidos = pt.ler_csv(pt.ARQ_PEDIDOS)
        cls.clientes = pt.ler_csv(pt.ARQ_CLIENTES)
        cls.linhas, cls.contagens = pt.transforma(cls.pedidos, cls.clientes)

    def test_contagens_medidas_na_eda(self):
        c = self.contagens
        self.assertEqual((c["linhas"], c["elegiveis"], c["atrasados"]), (99441, 96470, 6534))
        self.assertEqual((c["excluido_status_nao_entregue"], c["excluido_entregue_sem_data"]), (2963, 8))

    def test_grao_uma_linha_por_pedido(self):
        self.assertEqual(len({l["id_pedido"] for l in self.linhas}), len(self.linhas))

    def test_deterministico(self):
        linhas2, _ = pt.transforma(self.pedidos, self.clientes)
        self.assertEqual(pt.serializa_csv(self.linhas), pt.serializa_csv(linhas2))

    def test_referencia_da_pergunta(self):
        r = pt.resumo_pergunta(self.linhas)
        self.assertEqual((r["ufs"], r["elegiveis"], r["atrasados"]), (27, 96203, 6531))

    def test_execucao_a_partir_de_outro_diretorio(self):
        script = Path(pt.__file__).resolve()
        with tempfile.TemporaryDirectory() as d:
            proc = subprocess.run([sys.executable, str(script)], cwd=d, capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        dados = pt.ARQ_SAIDA.read_bytes()
        self.assertNotIn(b"\r", dados)
        self.assertIn(hashlib.sha256(dados).hexdigest(), pt.ARQ_MANIFESTO.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
