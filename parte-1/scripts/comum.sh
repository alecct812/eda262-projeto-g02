#!/usr/bin/env bash
# Funcoes compartilhadas por consulta.sh, verifica.sh e ciclo_completo.sh.
# Carregar com: source parte-1/scripts/comum.sh

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARTE1="$RAIZ/parte-1"
# A infraestrutura fica em us-east-1 (backend.tf e var.regiao). Os scripts usam a mesma regiao
# mesmo que o terminal tenha outro AWS_REGION exportado, para nao conferir a regiao errada.
export AWS_REGION="us-east-1" AWS_DEFAULT_REGION="us-east-1"
export AWS_PAGER=""

# Rede instavel ate o S3 (conexoes TCP de 6 s a mais de 12 s medidas em 2026-10-01): o timeout
# padrao de conexao da CLI e 60 s por tentativa, o que prendia uma chamada por minutos.
# Conexao curta com novas tentativas mantem cada chamada limitada e resiliente.
export AWS_RETRY_MODE="${AWS_RETRY_MODE:-standard}"
export AWS_MAX_ATTEMPTS="${AWS_MAX_ATTEMPTS:-8}"
aws() { command aws --cli-connect-timeout 5 --cli-read-timeout 60 "$@"; }

PRECO_USD_POR_TB="5.00"   # Athena, us-east-1, aws.amazon.com/athena/pricing (conferido em 2026-10-01)
MINIMO_BYTES=10000000     # minimo cobrado por consulta: 10 MB (convencao decimal, ver DECISOES.md)

exige_credenciais() {
  if ! aws sts get-caller-identity --query Account --output text >/dev/null 2>&1; then
    echo "ERRO: credenciais AWS ausentes ou invalidas. Exporte o perfil do grupo, por exemplo: export AWS_PROFILE=eda" >&2
    return 1
  fi
}

conta_aws() {
  aws sts get-caller-identity --query Account --output text
}

# tf_out NOME: le um output da raiz; ultima linha evita avisos misturados na saida.
tf_out() {
  terraform -chdir="$PARTE1" output -raw -no-color "$1" 2>/dev/null | tail -n 1
}

# athena_executa SQL BANCO WORKGROUP: inicia a consulta e imprime o QueryExecutionId.
athena_executa() {
  aws athena start-query-execution \
    --query-string "$1" \
    --query-execution-context "Database=$2" \
    --work-group "$3" \
    --query QueryExecutionId --output text
}

# athena_espera ID: aguarda o fim e imprime SUCCEEDED, FAILED ou CANCELLED.
athena_espera() {
  local estado
  while :; do
    estado=$(aws athena get-query-execution --query-execution-id "$1" \
      --query QueryExecution.Status.State --output text) || return 1
    case "$estado" in
      SUCCEEDED | FAILED | CANCELLED) echo "$estado"; return 0 ;;
    esac
    sleep 2
  done
}

athena_bytes() {
  aws athena get-query-execution --query-execution-id "$1" \
    --query QueryExecution.Statistics.DataScannedInBytes --output text
}

athena_motivo() {
  aws athena get-query-execution --query-execution-id "$1" \
    --query QueryExecution.Status.StateChangeReason --output text
}

# athena_resultado_csv ID: imprime o CSV que o Athena gravou no bucket de resultados.
athena_resultado_csv() {
  local uri
  uri=$(aws athena get-query-execution --query-execution-id "$1" \
    --query QueryExecution.ResultConfiguration.OutputLocation --output text)
  aws s3 cp "$uri" - | tr -d '\r'
}

# custo_usd BYTES: MB arredondado para cima, minimo de 10 MB, US$ por TB (1 TB = 10^12 B).
custo_usd() {
  awk -v b="$1" -v min="$MINIMO_BYTES" -v preco="$PRECO_USD_POR_TB" 'BEGIN {
    cobrado = int((b + 999999) / 1000000) * 1000000
    if (cobrado < min) cobrado = min
    printf "%.10f", cobrado / 1e12 * preco
  }'
}

# redige: troca o ID da conta por <ACCOUNT_ID> (evidencias sao versionadas).
redige() {
  if [ -n "${CONTA_AWS:-}" ]; then sed "s/${CONTA_AWS}/<ACCOUNT_ID>/g"; else cat; fi
}
