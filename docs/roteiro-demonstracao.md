# Roteiro de demonstração e captura de prints

Roteiro curto para executar o projeto à mão no terminal, ver as saídas e capturar os prints dos
slides (`docs/apresentacao.md`). Ele cobre o mesmo ciclo do README (deploy do zero, consulta com
custo, verificação e destroy), com as capturas mais úteis marcadas de P0 a P7.

**Saídas esperadas.** As saídas mostradas aqui são **resultados efetivamente observados** na
execução oficial de 03/10/2026 (`evidencias/ciclo-completo/`), exceto quando marcadas como
**exemplo**. Alguns valores mudam a cada execução e não devem ser comparados ao pé da letra: os IDs
de execução do Athena, os horários e o tempo de motor. Os números de recursos, bytes, custo e
resultado devem sair iguais.

Tempo total estimado: de 10 a 15 minutos, conforme a rede.

---

## Antes de começar: avisos

- **Cria recursos reais na AWS.** O ciclo cria 18 recursos na conta da turma. Custo estimado: menos
  de US$ 0,01. **Termine sempre com o destroy (passo 8)**, mesmo que algo dê errado no meio.
- **Conta compartilhada.** Não mexa em recursos de outros grupos, nem em `eda-tfstate-grupo02` e
  `eda-tflock`, que são do lab03.
- **ID da conta nos prints.** Alguns comandos podem mostrar o ID da conta AWS (12 dígitos), como o
  `aws sts get-caller-identity`. Antes de usar um print, confira e corte ou borre esse número.
- **Comandos que alteram arquivos:**
  - `consulta.sh` grava em `evidencias/manual/` e **substitui** os arquivos de uma execução manual
    anterior. Essa pasta fica fora do git, então isso não afeta as evidências oficiais.
  - Os testes do preparo (passo opcional 1) regravam a trusted e o manifesto com bytes idênticos.
  - O Terraform grava arquivos locais de state e cache: `parte-1/bootstrap/terraform.tfstate` e as
    pastas `.terraform/`. Eles ficam fora do git e **não devem ser apagados antes do destroy**.
  - **Não rode** `ciclo_completo.sh` para a demonstração. Ele cria uma nova pasta de evidências e
    faz tudo sem pausas para os prints.

## Pré-requisitos

| Item | Como conferir | Esperado |
| --- | --- | --- |
| Terraform >= 1.6 | `terraform version` | `Terraform v1.15.8` (usado na execução oficial) |
| AWS CLI v2 | `aws --version` | `aws-cli/2.34.54 ...` |
| bash | no Windows, abrir o **Git Bash** | prompt do bash |
| Credenciais do grupo | perfil configurado na AWS CLI (aqui, `eda`) | ver passo 0 |
| Repositório | clone de `eda262-projeto-g02` | pasta com `README.md`, `parte-1/`, `verificacao/` |

**Todos os comandos rodam na raiz do repositório** (a pasta que contém o `README.md`).

---

## Passo 0: preparar o terminal

```bash
cd <pasta do repositório>
export AWS_PROFILE=eda AWS_REGION=us-east-1
aws sts get-caller-identity --query Arn --output text
```

- **Esperado:** `arn:aws:iam::<ID da conta>:user/eda-grupo02`
- **Comprova:** as credenciais são as do grupo. **Não use este print**, porque ele mostra o ID da
  conta.

## Passo 1 (opcional): testes locais, sem AWS

```bash
python -m unittest discover -s parte-1/preparo      # no Linux/macOS: python3
bash parte-1/scripts/test_scripts.sh
```

- **Esperado:** `Ran 22 tests ... OK` e `todos os testes passaram`, em cerca de 1 minuto.
- **Comprova:** as regras do preparo e os scripts estão corretos.
- **Altera:** a trusted e o manifesto são regravados com bytes idênticos, então `git status`
  continua vazio.

## Passo 2: conta limpa

```bash
bash verificacao/verifica.sh --pos-destroy
```

- **Esperado:**
  ```
  PASSA  nenhum bucket eda262-g02-* (encontrados: 0)
  ...
  == RESUMO: 1 de 1 criterios PASSA
  ```
- **Comprova:** o deploy parte do zero (guia, seção 06: conta limpa).
- **Print P0 (slide 3).** Capture as linhas `PASSA` e o `RESUMO: 1 de 1`.

## Passo 3: backend remoto (bootstrap)

```bash
terraform -chdir=parte-1/bootstrap init
terraform -chdir=parte-1/bootstrap apply
```

- **Confirmação:** o `apply` mostra o plano e pergunta `Enter a value:`. Digite `yes`.
- **Esperado:** `Apply complete! Resources: 5 added, 0 changed, 0 destroyed.` e os outputs
  `bucket_state = "eda262-g02-tfstate"` e `tabela_trava = "eda262-g02-tflock"`.
- **Comprova:** o backend remoto (S3 + DynamoDB) foi criado do zero, sem passo manual.
- **Print P1 (slide 3).** Capture as últimas linhas, com `Apply complete` e os outputs.

## Passo 4: raiz com backend remoto e workspace

```bash
terraform -chdir=parte-1 init
terraform -chdir=parte-1 workspace select -or-create av1
```

- **Esperado:**
  - no `init`: `Successfully configured the backend "s3"!`, junto com um aviso amarelo
    `Deprecated Parameter` sobre `dynamodb_table` (esperado: o guia exige DynamoDB);
  - no workspace: `Created and switched to workspace "av1"!`.
- **Comprova:** módulo, backend remoto S3 + DynamoDB e workspace (guia 4.1).

**Variação opcional (print P3, slide 2 ou defesa).** Mostra o bloqueio do workspace `default`.
Rode **antes** do `workspace select`, logo depois do `init`:

```bash
terraform -chdir=parte-1 plan          # ainda no workspace default
```

- **Esperado:** `Error: Resource precondition failed` e
  `Workspace default bloqueado. Rode: terraform -chdir=parte-1 workspace select -or-create av1`.
- O comando não cria nada. Depois, siga com o `workspace select`.

## Passo 5: o Data Lake

```bash
terraform -chdir=parte-1 apply
```

- **Confirmação:** digite `yes` na pergunta.
- **Esperado:** `Plan: 13 to add, 0 to change, 0 to destroy.`, depois
  `Apply complete! Resources: 13 added, 0 changed, 0 destroyed.` e os outputs:
  ```
  banco_glue = "eda262_g02_entregas_ecommerce"
  bucket_raw = "eda262-g02-lake-raw"
  bucket_resultados = "eda262-g02-athena-results"
  bucket_trusted = "eda262-g02-lake-trusted"
  ...
  tabela_glue = "pedidos_entrega"
  workgroup = "eda262-g02-wg"
  ```
- **Tempo:** cerca de 1 minuto, porque envia 38 MB de dados.
- **Comprova:** bucket, catálogo e workgroup do zero; schema declarado; dados carregados pelo
  Terraform.
- **Print P2 (slide 3).** Capture `Apply complete! Resources: 13 added` com a lista de outputs.

## Passo 6: a pergunta no Athena, com custo

```bash
bash parte-1/consulta/consulta.sh
```

- **Esperado** (valores observados; o ID e o horário mudam a cada execução):
  ```
  query_execution_id=1428c728-1f33-4728-a01b-e0560caa68c2
  workgroup=eda262-g02-wg
  banco=eda262_g02_entregas_ecommerce
  estado=SUCCEEDED
  bytes_varridos=11167989
  tempo_motor_ms=1031
  preco_usd_por_tb=5.00
  minimo_cobrado_bytes=10000000
  custo_calculado_usd=0.0000600000
  --- resultado ---
  "uf_cliente","pedidos_elegiveis","pedidos_atrasados","taxa_atraso_pct","media_dias_atraso"
  "SP","40399","1817","4.5","8.3"
  "RJ","12310","1495","12.14","13.5"
  "MG","11319","519","4.59","8.4"
  ...
  ```
- **Comprova:** a pergunta respondida no Athena, com custo por consulta medido (guia 4.1).
- **Altera:** grava `evidencias/manual/consulta-execucao.txt` e `consulta-resultado.csv`
  (fora do git), substituindo os de uma execução manual anterior.
- **Print P4 (slide 4).** Capture do `estado=SUCCEEDED` até as primeiras UFs do resultado. É o
  print mais importante da apresentação.

## Passo 7: verificação de aceite

```bash
bash verificacao/verifica.sh
```

- **Esperado:** sete blocos `== Criterio N` com linhas `PASSA`, terminando com:
  ```
     => criterio 7: PASSA

  == RESUMO: 7 de 7 criterios PASSA
  ```
- **Tempo:** de 1 a 2 minutos. O script roda um `terraform plan` e duas consultas no Athena (custo
  de cerca de US$ 0,00012).
- **Comprova:** todos os requisitos técnicos, na própria conta (`verifica.sh` do guia, seção 06).
- **Print P5 (slide 5).** Capture o final, com os critérios 4 a 7 e o `RESUMO: 7 de 7`.

## Passo 7b (opcional): prints do console AWS (print P7, slides 2 e 4)

Com a stack ainda aplicada, no console da AWS (região **N. Virginia, us-east-1**):

- **S3:** os buckets `eda262-g02-lake-raw`, `eda262-g02-lake-trusted` e `eda262-g02-athena-results`.
- **Glue, Data Catalog, Tables:** a tabela `pedidos_entrega`, com as 10 colunas.
- **Athena, Query editor:** escolha o workgroup `eda262-g02-wg` e rode a consulta salva
  `eda262-g02-pergunta-atrasos-uf`. Capture o resultado e o campo "Data scanned".

**Exemplo:** o console mostra os bytes em MB arredondados, não o número exato. Confira se o ID da
conta não aparece no print.

## Passo 8: destroy (sempre, no fim)

```bash
terraform -chdir=parte-1 destroy
terraform -chdir=parte-1/bootstrap destroy
bash verificacao/verifica.sh --pos-destroy
```

- **Confirmação:** digite `yes` em cada `destroy`.
- **Ordem:** primeiro a raiz, depois o backend. O backend guarda o state da raiz; invertido, a raiz
  ficaria órfã.
- **Esperado:**
  - `Destroy complete! Resources: 13 destroyed.`
  - `Destroy complete! Resources: 5 destroyed.`
  - `== RESUMO: 1 de 1 criterios PASSA`, com 0 buckets, 0 databases, 0 workgroups e 0 tabelas do
    grupo
- **Comprova:** destroy limpo, sem recurso órfão (guia 4.1 e 06).
- **Print P6 (slide 6).** Capture as duas linhas `Destroy complete` e o resumo do pós-destroy.
  Uma montagem de dois prints funciona bem.

---

## Resumo dos prints

| Print | Passo | O que mostra | Slide | Item do guia (seção 7) |
| --- | --- | --- | --- | --- |
| **P0** | 2 | conta sem recursos do grupo | 3 | 3. apply do zero |
| **P1** | 3 | backend criado: `5 added` | 3 | 3. apply do zero |
| **P2** | 5 | Data Lake criado: `13 added` e outputs | 3 | 3. apply do zero |
| P3 (opcional) | 4, variação | workspace `default` bloqueado | 2 ou defesa | 2. arquitetura |
| **P4** | 6 | consulta `SUCCEEDED`, bytes e custo, primeiras UFs | 4 | 3. consulta respondida |
| **P5** | 7 | `7 de 7 criterios PASSA` | 5 | 3. custo medido e aceite |
| **P6** | 8 | `13 destroyed`, `5 destroyed`, pós-destroy limpo | 6 | 3. destroy |
| P7 (opcional) | 7b | console: buckets, tabela Glue, resultado no Athena | 2 e 4 | 2 e 3 |

Se não houver tempo de executar ao vivo, use a evidência gravada: os mesmos resultados estão em
`evidencias/ciclo-completo/` (P0 = `01-pre-verificacao.txt`, P1 = `04-bootstrap-apply.txt`, P2 =
`08-apply.txt`, P3 = `06-workspace-default-bloqueado.txt`, P4 = `10-consulta.txt`, P5 =
`11-verificacao.txt`, P6 = `12-destroy.txt`, `13-bootstrap-destroy.txt` e `14-pos-destroy.txt`). O
guia aceita "apply do zero ou evidência gravada" (seção 7).

## Se algo der errado

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| `ERRO: credenciais AWS ausentes ou invalidas` | `AWS_PROFILE` não exportado ou credencial errada | repetir o passo 0 |
| `Error acquiring the state lock` | um comando anterior foi interrompido | esperar e repetir; se persistir, `terraform -chdir=parte-1 force-unlock <ID mostrado no erro>` |
| Comandos lentos ou parados | rede lenta até o S3 (já observado) | aguardar; os scripts têm timeout curto com novas tentativas |
| `outputs do Terraform indisponiveis` no `consulta.sh` | o passo 5 não foi feito, ou o workspace não é `av1` | conferir com `terraform -chdir=parte-1 workspace show` |
| Erro no meio do apply | rede ou permissão | **rodar o passo 8 assim mesmo**, para não deixar recursos |
