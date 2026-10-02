#!/usr/bin/env bash
# Testes dos scripts bash com aws e terraform falsos: nao toca a AWS nem o state real.
# Uso (da raiz): bash parte-1/scripts/test_scripts.sh
set -u
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP=$(mktemp -d)
export FAKE_DIR="$TMP"
EVID_ANTES=$(ls -d "$RAIZ"/evidencias/execucao-* 2>/dev/null)
limpa() {
  # remove apenas pastas de evidencia criadas durante o teste
  for d in $(ls -d "$RAIZ"/evidencias/execucao-* 2>/dev/null); do
    printf '%s\n' "$EVID_ANTES" | grep -qxF "$d" || rm -rf "$d"
  done
  rm -rf "$TMP"
}
trap limpa EXIT
FALHAS=0
passa() { echo "ok     $1"; }
falha() { echo "FALHA  $1"; FALHAS=$((FALHAS + 1)); }

mkdir -p "$TMP/bin"
cat > "$TMP/bin/aws" <<'EOF'
#!/usr/bin/env bash
echo "AWS_REGION=${AWS_REGION:-} $*" >> "$FAKE_DIR/aws.log"
case "$*" in
  *get-caller-identity*) echo 123456789012 ;;
  *start-query-execution*) printf '%s' "$*" > "$FAKE_DIR/ultima_query"; echo "qid-falso" ;;
  *QueryExecution.Status.State*) echo SUCCEEDED ;;
  *DataScannedInBytes*) echo 11167989 ;;
  *EngineExecutionTimeInMillis*) echo 1000 ;;
  *OutputLocation*) echo "s3://falso/resultado.csv" ;;
  *"s3 cp"*)
    if grep -q "motivo_exclusao IS NULL" "$FAKE_DIR/ultima_query"; then
      printf '"_col0","_col1","_col2"\n"99441","99441","%s"\n' "${FAKE_NULOS:-96470}"
    elif grep -q "DISTINCT" "$FAKE_DIR/ultima_query"; then
      printf '"_col0","_col1"\n"99441","99441"\n'
    else
      cat "$FAKE_DIR/pergunta.csv"
    fi ;;
  *) echo 0 ;;
esac
exit 0
EOF
cat > "$TMP/bin/terraform" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_DIR/terraform.log"
case "$*" in
  *"-chdir=parte-1 apply"*) [ "${FAKE_FALHA_APPLY:-0}" = 1 ] && { echo "Error: falha simulada no apply"; exit 1; } ;;
  *"output -raw"*banco_glue*) printf 'eda262_g02_entregas_ecommerce' ;;
  *"output -raw"*tabela_glue*) printf 'pedidos_entrega' ;;
  *"output -raw"*workgroup*) printf 'eda262-g02-wg' ;;
  *detailed-exitcode*) exit 0 ;;
  *" plan "*) echo "Error: Resource precondition failed (workspace default)"; exit 1 ;;
esac
exit 0
EOF
chmod +x "$TMP/bin/aws" "$TMP/bin/terraform"
printf '%s\n' '"uf_cliente","pedidos_elegiveis","pedidos_atrasados","taxa_atraso_pct","media_dias_atraso"' \
  '"SP","40399","1817","4.5","8.3"' > "$TMP/pergunta.csv"
export PATH="$TMP/bin:$PATH"

# 1. Criterio 4 detecta campo vazio que nao virou nulo (Review Focus 4)
saida=$(FAKE_NULOS=0 bash "$RAIZ/verificacao/verifica.sh" 2>&1)
if printf '%s\n' "$saida" | grep -q "=> criterio 4: FALHA"; then
  passa "criterio 4 falha quando motivo_exclusao IS NULL nao da 96470"
else
  falha "criterio 4 nao detectou nulos errados (motivo_exclusao IS NULL = 0)"
fi
saida=$(FAKE_NULOS=96470 bash "$RAIZ/verificacao/verifica.sh" 2>&1)
if printf '%s\n' "$saida" | grep -q "=> criterio 4: PASSA"; then
  passa "criterio 4 passa com grao e nulos corretos"
else
  falha "criterio 4 deveria passar com 99441, 99441 e 96470"
fi

# 2. Regiao fixa em us-east-1 mesmo com AWS_REGION externo (evita PASSA falso no pos-destroy)
: > "$TMP/aws.log"
AWS_REGION=sa-east-1 bash "$RAIZ/verificacao/verifica.sh" --pos-destroy >/dev/null 2>&1
if [ -s "$TMP/aws.log" ] && ! grep -qv "^AWS_REGION=us-east-1 " "$TMP/aws.log"; then
  passa "todas as chamadas aws usam us-east-1 mesmo com AWS_REGION=sa-east-1"
else
  falha "chamadas aws com regiao diferente de us-east-1: $(grep -v '^AWS_REGION=us-east-1 ' "$TMP/aws.log" | head -n 1)"
fi

# 3. Falha no meio do ciclo destroi o que foi criado (sem recurso orfao)
: > "$TMP/terraform.log"
EVID_DIR="$TMP/evid" FAKE_FALHA_APPLY=1 bash "$RAIZ/parte-1/scripts/ciclo_completo.sh" >/dev/null 2>&1
rc=$?
if [ "$rc" -ne 0 ] && grep -q -- "-chdir=parte-1 destroy" "$TMP/terraform.log" &&
  grep -q -- "-chdir=parte-1/bootstrap destroy" "$TMP/terraform.log"; then
  passa "apply com falha: ciclo sai com rc=$rc e destroi raiz e bootstrap"
else
  falha "apply com falha: rc=$rc; destroys registrados: $(grep -c destroy "$TMP/terraform.log")"
fi

echo
if [ "$FALHAS" -eq 0 ]; then echo "todos os testes passaram"; else echo "$FALHAS teste(s) falharam"; fi
[ "$FALHAS" -eq 0 ]
