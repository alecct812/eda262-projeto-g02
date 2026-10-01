#!/usr/bin/env bash
# Ciclo completo do zero, gravando comandos e saidas em evidencias/execucao-<carimbo>/.
# Etapas: pre-verificacao, versoes, bootstrap, init, bloqueio do workspace default, workspace,
#         apply, state remoto, consulta, verificacao, destroy, destroy do bootstrap e pos-destroy.
# Se uma etapa falhar depois que algo foi criado, o script destroi tudo antes de sair (sem orfao).
# Uso (da raiz do repositorio): AWS_PROFILE=<perfil do grupo> bash parte-1/scripts/ciclo_completo.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/comum.sh"

exige_credenciais
export CONTA_AWS
CONTA_AWS=$(conta_aws)
CARIMBO=$(date -u +%Y%m%dT%H%M%SZ)
export EVID_DIR="${EVID_DIR:-$RAIZ/evidencias/execucao-$CARIMBO}"
mkdir -p "$EVID_DIR"
cd "$RAIZ"

N=0
# etapa NOME comando...: registra comando, horario, saida (redigida) e codigo de saida.
etapa() {
  N=$((N + 1))
  local arq rc
  arq=$(printf '%s/%02d-%s.txt' "$EVID_DIR" "$N" "$1")
  shift
  {
    echo "\$ $*"
    echo "# inicio (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } | tee "$arq"
  set +e
  "$@" 2>&1 | redige | tee -a "$arq"
  rc=${PIPESTATUS[0]}
  set -e
  echo "# fim (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ) | codigo de saida: $rc" | tee -a "$arq"
  return "$rc"
}

APLICADO=0
# Falha depois do bootstrap: destroi raiz e backend e confere, para nao deixar recurso orfao.
limpa_em_falha() {
  local rc=$?
  if [ "$rc" -ne 0 ] && [ "$APLICADO" -eq 1 ]; then
    echo "Etapa falhou (codigo $rc): destruindo o que foi criado para nao deixar recurso orfao." >&2
    set +e
    etapa limpeza-destroy terraform -chdir=parte-1 destroy -auto-approve -input=false -no-color
    etapa limpeza-bootstrap-destroy terraform -chdir=parte-1/bootstrap destroy -auto-approve -input=false -no-color
    etapa limpeza-pos-destroy bash verificacao/verifica.sh --pos-destroy
  fi
  exit "$rc"
}
trap limpa_em_falha EXIT

etapa pre-verificacao bash verificacao/verifica.sh --pos-destroy
etapa versoes bash -c 'terraform version; aws --version; uname -s'
etapa bootstrap-init terraform -chdir=parte-1/bootstrap init -input=false -no-color
APLICADO=1
etapa bootstrap-apply terraform -chdir=parte-1/bootstrap apply -auto-approve -input=false -no-color
etapa init terraform -chdir=parte-1 init -input=false -no-color -reconfigure
etapa workspace-default-bloqueado bash -c 'terraform -chdir=parte-1 plan -input=false -no-color; rc=$?; echo "codigo de saida do plan no workspace default: $rc (esperado: 1, precondicao)"; test "$rc" -eq 1'
etapa workspace terraform -chdir=parte-1 workspace select -or-create av1
etapa apply terraform -chdir=parte-1 apply -auto-approve -input=false -no-color
etapa state-remoto bash -c 'source parte-1/scripts/comum.sh; aws s3api head-object --bucket eda262-g02-tfstate --key eda262-g02/av1/parte-1/terraform.tfstate --query "[ContentLength, LastModified]" --output text'
etapa consulta bash parte-1/consulta/consulta.sh
etapa verificacao bash verificacao/verifica.sh
etapa destroy terraform -chdir=parte-1 destroy -auto-approve -input=false -no-color
etapa bootstrap-destroy terraform -chdir=parte-1/bootstrap destroy -auto-approve -input=false -no-color
APLICADO=0
etapa pos-destroy bash verificacao/verifica.sh --pos-destroy

if grep -rqF "$CONTA_AWS" "$EVID_DIR"; then
  echo "ERRO: o ID da conta apareceu nas evidencias; revise a redacao." >&2
  exit 1
fi
echo "Evidencias gravadas em ${EVID_DIR#"$RAIZ"/}"
