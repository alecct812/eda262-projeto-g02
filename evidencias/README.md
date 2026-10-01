# Evidências da execução registrada

Execução: `evidencias/execucao-20261001T230857Z/`, gerada em 01/10/2026 (UTC) por
`AWS_PROFILE=<perfil do grupo> bash parte-1/scripts/ciclo_completo.sh`, a partir de um **clone
limpo** do repositório (só arquivos versionados) e numa conta sem nenhum recurso `eda262-g02`.
Cada arquivo traz o comando executado, o horário de início e de fim (UTC), a saída completa e o
código de saída. O ID da conta AWS foi substituído por `<ACCOUNT_ID>`.

Ambiente: Terraform v1.15.8, provider aws 5.100.0, aws-cli 2.34.54, Git Bash (MINGW64) no
Windows 11, região us-east-1. Duração total: 4 min 34 s (23:08:57 a 23:13:31 UTC).

| # | Etapa | Comando | Resultado | Arquivo |
| --- | --- | --- | --- | --- |
| 01 | Pré-verificação (conta limpa) | `bash verificacao/verifica.sh --pos-destroy` | 0 buckets, 0 Glue databases, 0 workgroups e 0 tabelas DynamoDB do grupo; 1 de 1 critérios PASSA | `01-pre-verificacao.txt` |
| 02 | Versões | `terraform version; aws --version; uname -s` | Terraform v1.15.8, aws-cli 2.34.54, MINGW64 | `02-versoes.txt` |
| 03 | Init do backend | `terraform -chdir=parte-1/bootstrap init` | provider aws 5.100.0 instalado conforme o lock | `03-bootstrap-init.txt` |
| 04 | Apply do backend | `terraform -chdir=parte-1/bootstrap apply -auto-approve` | Apply complete! Resources: 5 added | `04-bootstrap-apply.txt` |
| 05 | Init da raiz | `terraform -chdir=parte-1 init -reconfigure` | Successfully configured the backend "s3" (com aviso esperado de depreciação do `dynamodb_table`) | `05-init.txt` |
| 06 | Workspace | `terraform -chdir=parte-1 workspace select -or-create av1` | Created and switched to workspace "av1" | `06-workspace.txt` |
| 07 | Apply do Data Lake | `terraform -chdir=parte-1 apply -auto-approve` | Apply complete! Resources: 13 added (3 buckets, 3 bloqueios públicos, 3 objetos, Glue database e tabela, workgroup, consulta salva) | `07-apply.txt` |
| 08 | Pergunta no Athena | `bash parte-1/consulta/consulta.sh` | SUCCEEDED, 11.167.989 bytes varridos, custo calculado US$ 0,00006, 27 UFs | `08-consulta.txt`, `consulta-execucao.txt`, `consulta-resultado.csv` |
| 09 | Verificação de aceite | `bash verificacao/verifica.sh` | 7 de 7 critérios PASSA | `09-verificacao.txt` |
| 10 | Destroy do Data Lake | `terraform -chdir=parte-1 destroy -auto-approve` | Destroy complete! Resources: 13 destroyed | `10-destroy.txt` |
| 11 | Destroy do backend | `terraform -chdir=parte-1/bootstrap destroy -auto-approve` | Destroy complete! Resources: 5 destroyed | `11-bootstrap-destroy.txt` |
| 12 | Pós-destroy (sem órfãos) | `bash verificacao/verifica.sh --pos-destroy` | 0 recursos do grupo restantes; 1 de 1 critérios PASSA | `12-pos-destroy.txt` |

## Consulta e custo

Arquivo `consulta-execucao.txt`:

| Campo | Valor |
| --- | --- |
| ID da execução | `71812375-ef2c-47b6-9cbf-b3d1cd6e98be` |
| Estado | SUCCEEDED |
| Bytes varridos (`DataScannedInBytes`) | 11.167.989 |
| Tempo de motor | 1.240 ms |
| Preço | US$ 5,00 por TB (us-east-1), mínimo de 10 MB por consulta |
| Custo calculado | 12 MB x US$ 5,00 / TB = **US$ 0,00006** |

A verificação (etapa 09) executou a pergunta de novo (execução
`48374482-4e26-446e-86a4-aaff7d7d95b6`) e conferiu 27 UFs com 96.203 pedidos elegíveis e 6.531
atrasados, os mesmos totais do cálculo local do preparo (`parte-1/dados/trusted/manifesto.json`).

## Resposta da pergunta

Em quais estados de destino a promessa de prazo foi mais descumprida entre jan/2017 e ago/2018?
Ordenado por pedidos atrasados e depois pela taxa (arquivo `consulta-resultado.csv`):

| # | UF | Pedidos elegíveis | Pedidos atrasados | Taxa de atraso (%) | Média de dias de atraso |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | SP | 40399 | 1817 | 4,5 | 8,3 |
| 2 | RJ | 12310 | 1495 | 12,14 | 13,5 |
| 3 | MG | 11319 | 519 | 4,59 | 8,4 |
| 4 | BA | 3253 | 396 | 12,17 | 12,0 |
| 5 | RS | 5327 | 325 | 6,1 | 10,2 |
| 6 | SC | 3537 | 291 | 8,23 | 8,3 |
| 7 | ES | 1992 | 214 | 10,74 | 11,3 |
| 8 | PR | 4903 | 199 | 4,06 | 8,3 |
| 9 | CE | 1273 | 176 | 13,83 | 15,2 |
| 10 | PE | 1587 | 153 | 9,64 | 12,0 |
| 11 | GO | 1950 | 128 | 6,56 | 11,4 |
| 12 | MA | 713 | 125 | 17,53 | 10,5 |
| 13 | DF | 2074 | 118 | 5,69 | 7,4 |
| 14 | PA | 942 | 106 | 11,25 | 12,8 |
| 15 | AL | 396 | 85 | 21,46 | 9,5 |
| 16 | MS | 701 | 68 | 9,7 | 8,3 |
| 17 | PI | 475 | 66 | 13,89 | 13,3 |
| 18 | PB | 516 | 54 | 10,47 | 10,3 |
| 19 | MT | 885 | 53 | 5,99 | 10,6 |
| 20 | SE | 332 | 51 | 15,36 | 16,2 |
| 21 | RN | 470 | 44 | 9,36 | 14,5 |
| 22 | TO | 274 | 27 | 9,85 | 6,5 |
| 23 | RO | 243 | 7 | 2,88 | 5,6 |
| 24 | RR | 40 | 5 | 12,5 | 36,4 |
| 25 | AM | 145 | 4 | 2,76 | 30,3 |
| 26 | AC | 80 | 3 | 3,75 | 18,7 |
| 27 | AP | 67 | 2 | 2,99 | 72,5 |

Leitura: SP tem o maior número de pedidos atrasados (1.817), mas com taxa baixa (4,5%). RJ junta
volume e taxa altos (1.495 pedidos, 12,14%) e é a prioridade mais clara de investigação. AL tem
a maior taxa (21,46%), porém sobre só 396 pedidos.
