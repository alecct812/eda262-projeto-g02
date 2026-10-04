# Evidências

Esta pasta guarda a prova de que o projeto funciona na AWS: o deploy do zero, a pergunta respondida
no Athena com o custo medido e o destroy sem recursos órfãos (guia, seções 4.1 e 06).

## O que são as evidências

São arquivos de texto de três tipos:

1. **Registros de execução** (`NN-etapa.txt`). Cada um traz:
   - o comando exato (linha que começa com `$`);
   - o horário de início e de fim, em UTC, pelo relógio da máquina;
   - a saída completa do comando, incluindo erros;
   - o código de saída (0 significa sucesso).

   O ID da conta AWS é substituído por `<ACCOUNT_ID>` e os códigos de cor do terminal são removidos
   (função `redige` em `parte-1/scripts/comum.sh`).
2. **Artefatos de dados**, que não são saída de terminal:
   - `consulta-execucao.txt`: metadados da consulta lidos da API do Athena (ID da execução, estado,
     bytes varridos, tempo de motor, preço e custo calculado);
   - `consulta-resultado.csv`: o arquivo de resultado que o próprio Athena gravou no bucket de
     resultados.
3. **Índices** (`README.md`): resumos escritos a partir dos arquivos acima.

## `ciclo-completo/`: a execução oficial

Gerada por `bash parte-1/scripts/ciclo_completo.sh` em 03/10/2026, entre 01:00:10 e 01:05:13 UTC
(5 min 03 s). A execução partiu de um **clone limpo** do commit `03f412a`, numa conta sem nenhum
recurso `eda262-g02`. Nenhum arquivo de código ou de dados mudou depois desse commit, então a
execução corresponde exatamente ao que está publicado.

Ambiente: Terraform v1.15.8, provider aws 5.100.0, aws-cli 2.34.54, Git Bash no Windows 11, região
us-east-1.

| # | Etapa | Resultado | O que comprova |
| --- | --- | --- | --- |
| 01 | `verifica.sh --pos-destroy` | 0 recursos do grupo na conta | conta limpa antes do deploy |
| 02 | versões | Terraform v1.15.8, aws-cli 2.34.54 | ambiente usado |
| 03 | `terraform -chdir=parte-1/bootstrap init` | provider 5.100.0, conforme o lock | dependências fixadas |
| 04 | `terraform -chdir=parte-1/bootstrap apply` | `Apply complete! Resources: 5 added` | backend remoto (S3 + DynamoDB) criado do zero |
| 05 | `terraform -chdir=parte-1 init` | `Successfully configured the backend "s3"` | raiz usando o backend remoto |
| 06 | `plan` no workspace `default` | `Error: Resource precondition failed`, código 1 | o `default` é bloqueado |
| 07 | `workspace select -or-create av1` | `Created and switched to workspace "av1"` | workspace nomeado |
| 08 | `terraform -chdir=parte-1 apply` | `Apply complete! Resources: 13 added`, com o plano completo | buckets, carga dos dados, Glue com schema declarado, workgroup |
| 09 | `aws s3api head-object` no state | 28.946 bytes em `eda262-g02/av1/parte-1/terraform.tfstate` | state remoto gravado |
| 10 | `bash parte-1/consulta/consulta.sh` | SUCCEEDED, 11.167.989 bytes, US$ 0,00006, 27 UFs | pergunta respondida com custo medido |
| 11 | `bash verificacao/verifica.sh` | `7 de 7 criterios PASSA` | todos os critérios de aceite |
| 12 | `terraform -chdir=parte-1 destroy` | `Destroy complete! Resources: 13 destroyed` | destroy do Data Lake |
| 13 | `terraform -chdir=parte-1/bootstrap destroy` | `Destroy complete! Resources: 5 destroyed` | destroy do backend |
| 14 | `verifica.sh --pos-destroy` | 0 recursos do grupo restantes | nenhum recurso órfão |

### Consulta e custo

Fonte: `ciclo-completo/consulta-execucao.txt`.

| Campo | Valor |
| --- | --- |
| ID da execução | `1428c728-1f33-4728-a01b-e0560caa68c2` |
| Estado | SUCCEEDED |
| Bytes varridos (`DataScannedInBytes`) | 11.167.989 |
| Tempo de motor | 1.031 ms |
| Custo calculado | 12 MB x US$ 5,00 / TB = **US$ 0,00006** |

A verificação (etapa 11) executou a pergunta de novo (execução
`faebe614-633d-46ae-b5cc-cf6cb20be893`). Ela conferiu 27 UFs, com 96.203 pedidos elegíveis e 6.531
atrasados, os mesmos totais do cálculo local em `parte-1/dados/trusted/manifesto.json`.

### Resposta da pergunta (`ciclo-completo/consulta-resultado.csv`)

As cinco UFs com mais pedidos atrasados entre jan/2017 e ago/2018:

| UF | Pedidos elegíveis | Pedidos atrasados | Taxa de atraso |
| --- | ---: | ---: | ---: |
| SP | 40.399 | 1.817 | 4,50% |
| RJ | 12.310 | 1.495 | 12,14% |
| MG | 11.319 | 519 | 4,59% |
| BA | 3.253 | 396 | 12,17% |
| RS | 5.327 | 325 | 6,10% |

A maior taxa é a de AL (21,46%, com 85 atrasados em 396 pedidos). A tabela completa, com as 27
UFs, está no CSV.

## `verificacoes-complementares/`: checagens independentes

Sete checagens feitas em 03/10/2026 com a stack aplicada, durante a revisão de primeira utilização.
Elas comprovam pontos que o `verifica.sh` não cobre e que o `DECISOES.md` cita. O índice está em
`verificacoes-complementares/README.md`.

## Execuções novas e material fora do repositório

Uma nova execução de `ciclo_completo.sh` cria `evidencias/execucao-<carimbo>/` ao lado destas.
Execuções manuais de `consulta.sh` gravam em `evidencias/manual/`, que fica fora do git.

Os registros de execuções anteriores, todas com o mesmo resultado, não estão publicados. Eles
continuam no histórico do git (commits `7777c3c` e `03f412a`):

- o ciclo completo de 02/10;
- a revisão completa de 03/10 (35 etapas, incluindo o passo a passo do README feito à mão e
  checagens que falharam por erro do próprio script de checagem e foram refeitas).
