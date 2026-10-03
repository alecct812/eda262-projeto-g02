#!/usr/bin/env bash
# Executa a pergunta de negocio no Athena e registra execucao, bytes varridos e custo.
# Uso (da raiz ou de qualquer pasta): bash parte-1/consulta/consulta.sh
# EVID_DIR (opcional) define a pasta de evidencias; padrao: evidencias/manual
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../scripts/comum.sh"

exige_credenciais
CONTA_AWS=$(conta_aws)
EVID_DIR="${EVID_DIR:-$RAIZ/evidencias/manual}"
mkdir -p "$EVID_DIR"

# || true: sem state ou sem init, o terraform output falha e o set -e encerraria sem mensagem.
BANCO=$(tf_out banco_glue || true)
WG=$(tf_out workgroup || true)
if [ -z "$BANCO" ] || [ -z "$WG" ]; then
  echo "ERRO: outputs do Terraform indisponiveis. Rode o apply no workspace av1 antes." >&2
  exit 1
fi

SQL=$(cat "$PARTE1/consulta/pergunta.sql")
QID=$(athena_executa "$SQL" "$BANCO" "$WG")
ESTADO=$(athena_espera "$QID")
BYTES=$(athena_bytes "$QID")
TEMPO=$(aws athena get-query-execution --query-execution-id "$QID" \
  --query QueryExecution.Statistics.EngineExecutionTimeInMillis --output text)

{
  echo "data_execucao_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "query_execution_id=$QID"
  echo "workgroup=$WG"
  echo "banco=$BANCO"
  echo "estado=$ESTADO"
  echo "bytes_varridos=$BYTES"
  echo "tempo_motor_ms=$TEMPO"
  echo "preco_usd_por_tb=$PRECO_USD_POR_TB"
  echo "minimo_cobrado_bytes=$MINIMO_BYTES"
  echo "custo_calculado_usd=$(custo_usd "$BYTES")"
} | redige | tee "$EVID_DIR/consulta-execucao.txt"

if [ "$ESTADO" != "SUCCEEDED" ]; then
  echo "ERRO: consulta $ESTADO: $(athena_motivo "$QID")" >&2
  exit 1
fi

echo "--- resultado ---"
athena_resultado_csv "$QID" | tee "$EVID_DIR/consulta-resultado.csv"
