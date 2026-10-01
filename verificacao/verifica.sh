#!/usr/bin/env bash
# Verificacao de aceite da Parte 1 (AV1, grupo g02). Imprime PASSA/FALHA por criterio.
# Uso: bash verificacao/verifica.sh                 (stack aplicada, workspace av1)
#      bash verificacao/verifica.sh --pos-destroy   (confere que nao sobrou recurso)
# Requer AWS CLI v2, Terraform e credenciais do grupo (export AWS_PROFILE=<perfil>).
set -uo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../parte-1/scripts/comum.sh"

GRUPO="${GRUPO:-g02}"
PREFIXO="eda262-$GRUPO"
# Valores medidos pelo preparo (parte-1/dados/trusted/manifesto.json)
ESPERADO_LINHAS=99441
ESPERADO_UFS=27
ESPERADO_ELEGIVEIS=96203
ESPERADO_ATRASADOS=6531

TOTAL=0; APROVADOS=0; FALHAS=0; FALHOU_NO_CRITERIO=0
fim_criterio() {
  [ "$TOTAL" -eq 0 ] && return 0
  if [ "$FALHOU_NO_CRITERIO" -eq 0 ]; then APROVADOS=$((APROVADOS + 1)); echo "   => criterio $TOTAL: PASSA"
  else echo "   => criterio $TOTAL: FALHA"; fi
}
criterio() { fim_criterio; TOTAL=$((TOTAL + 1)); FALHOU_NO_CRITERIO=0; echo; echo "== Criterio $TOTAL: $1"; }
ok()   { echo "PASSA  $1"; }
nao()  { echo "FALHA  $1"; FALHOU_NO_CRITERIO=1; FALHAS=$((FALHAS + 1)); }
info() { echo "INFO   $1"; }
checa() { local desc="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$desc"; else nao "$desc"; fi; }
resumo() { fim_criterio; echo; echo "== RESUMO: $APROVADOS de $TOTAL criterios PASSA"; [ "$FALHAS" -eq 0 ]; exit $?; }

exige_credenciais || exit 1
CONTA=$(conta_aws)

if [ "${1:-}" = "--pos-destroy" ]; then
  criterio "Destroy limpo: nenhum recurso $PREFIXO restante (Guia 4.1 e 06)"
  N=$(aws s3api list-buckets --query "length(Buckets[?starts_with(Name, '$PREFIXO-')])" --output text)
  checa "nenhum bucket $PREFIXO-* (encontrados: $N)" test "$N" = "0"
  N=$(aws glue get-databases --query "length(DatabaseList[?starts_with(Name, 'eda262_${GRUPO}_')])" --output text)
  checa "nenhum Glue database eda262_${GRUPO}_* (encontrados: $N)" test "$N" = "0"
  N=$(aws athena list-work-groups --query "length(WorkGroups[?starts_with(Name, '$PREFIXO-')])" --output text)
  checa "nenhum workgroup $PREFIXO-* (encontrados: $N)" test "$N" = "0"
  N=$(aws dynamodb list-tables --query "length(TableNames[?starts_with(@, '$PREFIXO-')])" --output text)
  checa "nenhuma tabela DynamoDB $PREFIXO-* (encontradas: $N)" test "$N" = "0"
  N=$(aws resourcegroupstaggingapi get-resources --tag-filters "Key=grupo,Values=$GRUPO" "Key=turma,Values=eda262" \
    --query 'length(ResourceTagMappingList)' --output text)
  info "recursos ainda indexados com tag grupo=$GRUPO: $N (a API de tags pode levar minutos para refletir exclusoes)"
  resumo
fi

BANCO=$(tf_out banco_glue); BANCO=${BANCO:-eda262_${GRUPO}_entregas_ecommerce}
TABELA=$(tf_out tabela_glue); TABELA=${TABELA:-pedidos_entrega}
WG=$(tf_out workgroup); WG=${WG:-$PREFIXO-wg}
WS=$(cat "$PARTE1/.terraform/environment" 2>/dev/null || echo default)

criterio "Bucket, catalogo (Glue Data Catalog) e workgroup do Athena provisionados"
for b in "$PREFIXO-lake-raw" "$PREFIXO-lake-trusted" "$PREFIXO-athena-results"; do
  checa "bucket $b existe" aws s3api head-bucket --bucket "$b"
done
checa "Glue database $BANCO existe" aws glue get-database --name "$BANCO"
ESTADO_WG=$(aws athena get-work-group --work-group "$WG" --query WorkGroup.State --output text 2>/dev/null)
checa "workgroup $WG existe e esta ENABLED" test "$ESTADO_WG" = "ENABLED"

criterio "Stack em modulo, backend remoto S3 + DynamoDB e workspace"
checa "raiz chama module \"lake\"" grep -q 'module "lake"' "$PARTE1/main.tf"
checa "backend s3 declarado" grep -q 'backend "s3"' "$PARTE1/backend.tf"
checa "trava DynamoDB declarada no backend" grep -q 'dynamodb_table' "$PARTE1/backend.tf"
checa "workspace atual ($WS) e nomeado, diferente de default" test "$WS" != "default"
checa "state remoto em s3://$PREFIXO-tfstate/$PREFIXO/$WS/parte-1/terraform.tfstate" \
  aws s3api head-object --bucket "$PREFIXO-tfstate" --key "$PREFIXO/$WS/parte-1/terraform.tfstate"
ESTADO_TRAVA=$(aws dynamodb describe-table --table-name "$PREFIXO-tflock" --query Table.TableStatus --output text 2>/dev/null)
checa "tabela de trava $PREFIXO-tflock ACTIVE" test "$ESTADO_TRAVA" = "ACTIVE"
terraform -chdir="$PARTE1" plan -input=false -no-color -detailed-exitcode -lock-timeout=60s >/dev/null 2>&1
RC_PLAN=$?
checa "plan sem mudancas pendentes: infraestrutura igual ao codigo (rc=$RC_PLAN)" test "$RC_PLAN" -eq 0

criterio "Schema declarado no IaC, sem Crawler"
if grep -rq --include='*.tf' --exclude-dir=.terraform 'aws_glue_crawler' "$PARTE1"; then
  nao "nenhum aws_glue_crawler no codigo"
else
  ok "nenhum aws_glue_crawler no codigo"
fi
NCOL=$(aws glue get-table --database-name "$BANCO" --name "$TABELA" \
  --query 'length(Table.StorageDescriptor.Columns)' --output text 2>/dev/null)
checa "tabela $TABELA com 10 colunas declaradas (obtido: ${NCOL:-nada})" test "$NCOL" = "10"
SERDE=$(aws glue get-table --database-name "$BANCO" --name "$TABELA" \
  --query Table.StorageDescriptor.SerdeInfo.SerializationLibrary --output text 2>/dev/null)
checa "SerDe declarado: LazySimpleSerDe" test "$SERDE" = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

criterio "Tabela trusted modelada com grao declarado (uma linha por pedido)"
QID=$(athena_executa "SELECT count(*), count(DISTINCT id_pedido) FROM $TABELA" "$BANCO" "$WG")
EST=$(athena_espera "$QID")
checa "consulta de grao SUCCEEDED" test "$EST" = "SUCCEEDED"
GRAO=$(athena_resultado_csv "$QID" | tail -n 1 | tr -d '"')
checa "count(*) = count(DISTINCT id_pedido) = $ESPERADO_LINHAS (obtido: $GRAO)" \
  test "$GRAO" = "$ESPERADO_LINHAS,$ESPERADO_LINHAS"

criterio "Pergunta respondida no Athena com custo por consulta medido"
QID=$(athena_executa "$(cat "$PARTE1/consulta/pergunta.sql")" "$BANCO" "$WG")
EST=$(athena_espera "$QID")
BYTES=$(athena_bytes "$QID")
checa "pergunta SUCCEEDED (execucao $QID)" test "$EST" = "SUCCEEDED"
RES=$(athena_resultado_csv "$QID" | tr -d '"' | tail -n +2)
NUFS=$(printf '%s\n' "$RES" | grep -c .)
SOMAS=$(printf '%s\n' "$RES" | awk -F, '{e += $2; a += $3} END {print e "," a}')
checa "$ESPERADO_UFS UFs no resultado (obtido: $NUFS)" test "$NUFS" = "$ESPERADO_UFS"
checa "totais iguais ao calculo local: $ESPERADO_ELEGIVEIS elegiveis, $ESPERADO_ATRASADOS atrasados (obtido: $SOMAS)" \
  test "$SOMAS" = "$ESPERADO_ELEGIVEIS,$ESPERADO_ATRASADOS"
checa "bytes varridos medidos: ${BYTES:-0}" test "${BYTES:-0}" -gt 0
info "custo calculado da consulta: US\$ $(custo_usd "${BYTES:-0}") (US\$ $PRECO_USD_POR_TB por TB, minimo 10 MB)"

criterio "Tags obrigatorias (turma, grupo, projeto) nos recursos que aceitam tags"
tem_tags() { # recebe linhas chave=valor
  printf '%s\n' "$1" | grep -qx "turma=eda262" &&
    printf '%s\n' "$1" | grep -qx "grupo=$GRUPO" &&
    printf '%s\n' "$1" | grep -qx "projeto=engenharia-de-dados"
}
for b in "$PREFIXO-lake-raw" "$PREFIXO-lake-trusted" "$PREFIXO-athena-results" "$PREFIXO-tfstate"; do
  T=$(aws s3api get-bucket-tagging --bucket "$b" --query 'TagSet[].[Key,Value]' --output text 2>/dev/null | tr '\t' '=')
  checa "tags no bucket $b" tem_tags "$T"
done
T=$(aws athena list-tags-for-resource --resource-arn "arn:aws:athena:$AWS_REGION:$CONTA:workgroup/$WG" \
  --query 'Tags[].[Key,Value]' --output text 2>/dev/null | tr '\t' '=')
checa "tags no workgroup $WG" tem_tags "$T"
T=$(aws glue get-tags --resource-arn "arn:aws:glue:$AWS_REGION:$CONTA:database/$BANCO" \
  --query 'Tags | [turma, grupo, projeto]' --output text 2>/dev/null)
checa "tags no Glue database $BANCO" test "$T" = "eda262"$'\t'"$GRUPO"$'\t'"engenharia-de-dados"
ARN_TRAVA=$(aws dynamodb describe-table --table-name "$PREFIXO-tflock" --query Table.TableArn --output text 2>/dev/null)
T=$(aws dynamodb list-tags-of-resource --resource-arn "$ARN_TRAVA" --query 'Tags[].[Key,Value]' --output text 2>/dev/null | tr '\t' '=')
checa "tags na tabela de trava $PREFIXO-tflock" tem_tags "$T"
T=$(aws s3api get-object-tagging --bucket "$PREFIXO-lake-trusted" --key pedidos_entrega/pedidos_entrega.csv \
  --query 'TagSet[].[Key,Value]' --output text 2>/dev/null | tr '\t' '=')
checa "tags no objeto trusted pedidos_entrega.csv" tem_tags "$T"
info "tabela Glue e consulta salva do Athena nao aceitam tags (documentado no README)"

criterio "DECISOES.md com grao, chaves, particao, formato e custo"
D="$RAIZ/DECISOES.md"
checa "DECISOES.md existe na raiz" test -f "$D"
for tema in "Grão" "Chave" "Partição" "Formato" "Custo"; do
  checa "DECISOES.md trata de: $tema" grep -qF "$tema" "$D"
done
checa "DECISOES.md traz numeros medidos (blocos Medido:)" grep -qF "Medido:" "$D"

resumo
