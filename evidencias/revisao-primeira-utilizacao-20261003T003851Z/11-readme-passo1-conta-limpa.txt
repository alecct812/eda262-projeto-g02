# objetivo: README passo 1 / Guia 06 (conta limpa): confirmar que a conta nao tem recursos do grupo antes do deploy
# diretorio: eda262-g02-revisao
# comando: bash verificacao/verifica.sh --pos-destroy
# inicio (UTC): 2026-10-03T00:43:15Z
# ---- saida ----
Regiao: us-east-1 | grupo: g02

== Criterio 1: Destroy limpo: nenhum recurso eda262-g02 restante (Guia 4.1 e 06)
PASSA  nenhum bucket eda262-g02-* (encontrados: 0)
PASSA  nenhum Glue database eda262_g02_* (encontrados: 0)
PASSA  nenhum workgroup eda262-g02-* (encontrados: 0)
PASSA  nenhuma tabela DynamoDB eda262-g02-* (encontradas: 0)
INFO   recursos ainda indexados com tag grupo=g02: 0 (a API de tags pode levar minutos para refletir exclusoes)
   => criterio 1: PASSA

== RESUMO: 1 de 1 criterios PASSA
# ---- fim (UTC): 2026-10-03T00:43:33Z | codigo de saida: 0
