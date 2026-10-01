# Projeto de Engenharia de Dados, Parte 1 (AV1), grupo g02

CESAR School, Engenharia de Dados, 2026.2. Data Lake provisionado 100% em Terraform que
responde a uma pergunta de negócio no Amazon Athena e registra o custo da consulta.

## Cenário e pergunta de negócio

Cenário `entregas-ecommerce`: um marketplace promete ao cliente uma data de entrega e parte
dos pedidos chega depois dela. A equipe de operações precisa saber para onde direcionar a
investigação de atrasos e onde rever o prazo prometido.

**Pergunta:** em quais estados de destino a promessa de prazo foi mais descumprida entre
jan/2017 e ago/2018, considerando a quantidade e a taxa de pedidos entregues após a data prevista?

A resposta (27 UFs) traz pedidos elegíveis, pedidos atrasados, taxa de atraso e média de dias
de atraso, ordenada por quantidade de atrasados e depois pela taxa. Dados: pedidos e clientes
do dataset público da Olist (ver [Dados e licença](#dados-e-licença)).

## Arquitetura

```
CSV brutos (Olist)  ->  preparo/prepara_trusted.py  ->  trusted pedidos_entrega.csv
        |                                                     |
        v                                                     v
S3 eda262-g02-lake-raw                          S3 eda262-g02-lake-trusted
                                                              |
                         Glue Data Catalog: eda262_g02_entregas_ecommerce.pedidos_entrega
                         (schema declarado no Terraform, sem Crawler)
                                                              |
                         Athena workgroup eda262-g02-wg  ->  S3 eda262-g02-athena-results
```

| Recurso | Nome | Criado por |
| --- | --- | --- |
| Bucket de state | `eda262-g02-tfstate` (versionado, SSE, sem acesso público) | `parte-1/bootstrap` |
| Tabela de trava | `eda262-g02-tflock` (DynamoDB, chave `LockID`) | `parte-1/bootstrap` |
| Bucket bruto | `eda262-g02-lake-raw` (CSVs originais) | módulo `lake` |
| Bucket trusted | `eda262-g02-lake-trusted` (`pedidos_entrega/pedidos_entrega.csv`) | módulo `lake` |
| Bucket de resultados | `eda262-g02-athena-results` | módulo `lake` |
| Glue database | `eda262_g02_entregas_ecommerce` | módulo `lake` |
| Glue table | `pedidos_entrega` (10 colunas, LazySimpleSerDe) | módulo `lake` |
| Athena workgroup | `eda262-g02-wg` (configuração imposta, teto de 50 MiB por consulta) | módulo `lake` |
| Consulta salva | `eda262-g02-pergunta-atrasos-uf` | módulo `lake` |

Todos os recursos que aceitam tags levam `turma=eda262`, `grupo=g02` e
`projeto=engenharia-de-dados` (via `default_tags`). A tabela Glue e a consulta salva do Athena
não aceitam tags na API da AWS.

## Pré-requisitos

- Terraform >= 1.6 (testado com 1.15.8) e provider `hashicorp/aws` 5.100.0 (fixado em `.terraform.lock.hcl`).
- AWS CLI v2 e bash (no Windows, Git Bash).
- Credenciais do grupo exportadas no terminal, por exemplo `export AWS_PROFILE=<perfil do grupo>`.
  O código não fixa perfil nem ID de conta: funciona na conta de quem executa.
- Python >= 3.10, apenas para regenerar a trusted ou rodar os testes do preparo.

## Região, conta e backend

- Região: `us-east-1`.
- Conta: a do avaliador, com credenciais do grupo; nenhum recurso precisa existir antes.
- Backend: S3 `eda262-g02-tfstate` com trava DynamoDB `eda262-g02-tflock`, ambos criados pela
  stack `parte-1/bootstrap` (state local). A raiz `parte-1/` usa o workspace `av1`, com o state
  em `eda262-g02/av1/parte-1/terraform.tfstate`. O workspace `default` é bloqueado por uma
  precondição.
- O Terraform mostra o aviso `The parameter "dynamodb_table" is deprecated`: é esperado. A trava
  em DynamoDB continua suportada e é exigida pelo guia da disciplina.

## Passo a passo do apply do zero

Todos os comandos rodam na raiz do repositório.

```bash
# 0. Credenciais e região
export AWS_PROFILE=<perfil do grupo> AWS_REGION=us-east-1

# 1. Confirmar que a conta não tem recursos do grupo (esperado: "1 de 1 criterios PASSA")
bash verificacao/verifica.sh --pos-destroy

# 2. Backend remoto (esperado: "Apply complete! Resources: 5 added")
terraform -chdir=parte-1/bootstrap init
terraform -chdir=parte-1/bootstrap apply

# 3. Raiz com backend remoto e workspace (esperado: "Successfully configured the backend \"s3\"")
terraform -chdir=parte-1 init
terraform -chdir=parte-1 workspace select -or-create av1

# 4. Data Lake (esperado: "Apply complete! Resources: 13 added")
terraform -chdir=parte-1 apply

# 5. Pergunta no Athena com custo (esperado: "estado=SUCCEEDED" e 27 UFs no resultado)
bash parte-1/consulta/consulta.sh

# 6. Verificação de aceite (esperado: "7 de 7 criterios PASSA")
bash verificacao/verifica.sh
```

## Consulta e custo

`parte-1/consulta/consulta.sh` executa `parte-1/consulta/pergunta.sql` no workgroup e grava em
`evidencias/manual/` (ou em `$EVID_DIR`):

- `consulta-execucao.txt`: ID da execução, estado, bytes varridos (`DataScannedInBytes`),
  tempo de motor e custo calculado;
- `consulta-resultado.csv`: a resposta da pergunta.

Custo calculado: `max(MB arredondado para cima, 10 MB) x US$ 5,00 / TB`, com 1 MB = 10^6 bytes
e 1 TB = 10^12 bytes (preço do Athena em us-east-1, consultado em 01/10/2026). É um custo
calculado a partir dos bytes medidos, não o valor faturado. Os números medidos estão no
[DECISOES.md](DECISOES.md).

## Verificação

`bash verificacao/verifica.sh` imprime PASSA/FALHA por critério e termina com código 0 só se
todos passarem:

1. Buckets, Glue database e workgroup existem.
2. Módulo `lake`, backend S3 + DynamoDB, state no bucket, workspace nomeado e `plan` sem mudanças.
3. Schema declarado no Terraform (10 colunas, LazySimpleSerDe) e nenhum Crawler.
4. Grão: `count(*) = count(DISTINCT id_pedido) = 99441` no Athena.
5. Pergunta respondida (27 UFs, totais iguais ao cálculo local) com bytes e custo medidos.
6. Tags obrigatórias nos buckets, workgroup, Glue database, tabela de trava e objeto trusted.
7. `DECISOES.md` com grão, chaves, partição, formato e custo.

`bash verificacao/verifica.sh --pos-destroy` confere que não restou bucket, Glue database,
workgroup nem tabela DynamoDB com o prefixo do grupo.

## Destroy

```bash
# 1. Data Lake (esperado: "Destroy complete! Resources: 13 destroyed")
terraform -chdir=parte-1 destroy
# 2. Backend, por último, porque guarda o state da etapa anterior (esperado: "5 destroyed")
terraform -chdir=parte-1/bootstrap destroy
# 3. Conferência (esperado: "1 de 1 criterios PASSA")
bash verificacao/verifica.sh --pos-destroy
```

Todos os buckets usam `force_destroy`, inclusive o de state (apaga todas as versões), e o
workgroup também. Por isso o destroy não deixa recurso órfão nem exige limpeza manual.

## Execução registrada (evidências)

`bash parte-1/scripts/ciclo_completo.sh` executa o ciclo inteiro do zero (pré-verificação,
bootstrap, init, workspace, apply, consulta, verificação, destroy, destroy do backend e
pós-destroy) e grava cada comando com sua saída, horários e código de saída em
`evidencias/execucao-<carimbo>/`. O ID da conta é substituído por `<ACCOUNT_ID>`. O resumo da
execução entregue está em [evidencias/README.md](evidencias/README.md).

Os scripts usam timeout de conexão curto com novas tentativas na AWS CLI, porque a rede usada
nos testes teve conexões lentas com o S3.

## Estrutura do repositório

```
README.md, DECISOES.md
parte-1/
  bootstrap/            backend remoto (state local)
  *.tf                  raiz: backend, provider, workspace, chamada do módulo
  modules/lake/         buckets, objetos, Glue, workgroup e consulta salva
  dados/raw/            CSVs originais da Olist e FONTE.md
  dados/trusted/        pedidos_entrega.csv e manifesto.json (gerados pelo preparo)
  preparo/              prepara_trusted.py e testes
  consulta/             pergunta.sql e consulta.sh
  scripts/              comum.sh e ciclo_completo.sh
verificacao/verifica.sh
evidencias/             execução registrada
exploracao/             análise exploratória inicial (ferramenta auxiliar)
```

## Dados e licença

Fonte: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
licença [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Uso acadêmico e
não comercial, sem apoio ou endosso da Olist. Os arquivos brutos estão sem alteração em
`parte-1/dados/raw/` (hashes em [FONTE.md](parte-1/dados/raw/FONTE.md)). A trusted é uma
adaptação (seleção de colunas, junção, tipos e regras de elegibilidade) distribuída sob a mesma
licença.

Para regenerar a trusted e rodar os testes do preparo:

```bash
python parte-1/preparo/prepara_trusted.py
python -m unittest discover -s parte-1/preparo -v
```

O preparo é determinístico: a saída tem o mesmo SHA-256 registrado em
`parte-1/dados/trusted/manifesto.json`. A análise em `exploracao/` precisa do download completo
do Kaggle em `dataset/archive/` (fora do repositório).

## Limitações

- O dataset é um recorte histórico (compras de set/2016 a out/2018). A resposta descreve esse
  período, não o e-commerce atual.
- O dado não traz transportadora nem causa do atraso: a análise indica onde investigar, não por quê.
- O custo é calculado a partir dos bytes medidos, não lido da fatura.
- Tabela Glue e consulta salva do Athena não aceitam tags.
- Fora do escopo da Parte 1, conforme o guia: Parquet, particionamento, camadas e idempotência.
