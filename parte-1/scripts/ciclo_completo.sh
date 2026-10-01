#!/usr/bin/env bash
# Ciclo completo do zero, gravando comandos e saidas em evidencias/execucao-<carimbo>/.
# Etapas: pre-verificacao, versoes, bootstrap, init, workspace, apply, consulta,
#         verificacao, destroy, destroy do bootstrap e pos-destroy.
# Uso (da raiz do repositorio): AWS_PROFILE=<perfil do grupo> bash parte-1/scripts/ciclo_completo.sh
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/comum.sh"

exige_credenciais
export CONTA_AWS
CONTA_AWS=$(conta_aws)
CARIMBO=$(date -u +%Y%m%dT%H%M%SZ)
export EVID_DIR="$RAIZ/evidencias/execucao-$CARIMBO"
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

etapa pre-verificacao bash verificacao/verifica.sh --pos-destroy
etapa versoes bash -c 'terraform version; aws --version; uname -s'
etapa bootstrap-init terraform -chdir=parte-1/bootstrap init -input=false -no-color
etapa bootstrap-apply terraform -chdir=parte-1/bootstrap apply -auto-approve -input=false -no-color
etapa init terraform -chdir=parte-1 init -input=false -no-color -reconfigure
etapa workspace terraform -chdir=parte-1 workspace select -or-create av1
etapa apply terraform -chdir=parte-1 apply -auto-approve -input=false -no-color
etapa consulta bash parte-1/consulta/consulta.sh
etapa verificacao bash verificacao/verifica.sh
etapa destroy terraform -chdir=parte-1 destroy -auto-approve -input=false -no-color
etapa bootstrap-destroy terraform -chdir=parte-1/bootstrap destroy -auto-approve -input=false -no-color
etapa pos-destroy bash verificacao/verifica.sh --pos-destroy

if grep -rqF "$CONTA_AWS" "$EVID_DIR"; then
  echo "ERRO: o ID da conta apareceu nas evidencias; revise a redacao." >&2
  exit 1
fi
echo "Evidencias gravadas em ${EVID_DIR#"$RAIZ"/}"
