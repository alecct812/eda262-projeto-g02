# DECISOES.md: Parte 1 (AV1), grupo g02

Cenário `entregas-ecommerce` · região `us-east-1` · Terraform 1.15.8 · provider aws 5.100.0 ·
dados: Olist, CC BY-NC-SA 4.0 · pergunta: atrasos de entrega por UF de destino, jan/2017 a ago/2018.

Cada decisão diz o que escolhemos, o que aceitamos perder, por que não as alternativas e o
número que a sustenta. Fontes dos números: `parte-1/dados/trusted/manifesto.json` (preparo),
`exploracao/saida/perfil_olist.json` (análise exploratória) e `evidencias/` (execução na AWS).

## DECISÃO 01: Grão da trusted é um pedido

A tabela `pedidos_entrega` tem uma linha por pedido, com os 99.441 pedidos da origem, inclusive
os que não entram no indicador (marcados com `elegivel = false` e o motivo). A pergunta é sobre
a promessa de prazo, que é feita por pedido: contar itens faria um pedido com três itens pesar
três vezes. **Aceitamos perder** o detalhe por item e por vendedor (frete, produto, origem),
que esta pergunta não usa. Manter todos os pedidos, e não só os elegíveis, deixa o denominador
auditável no Athena.

> **Medido:** 99.441 linhas = 99.441 `id_pedido` distintos (critério 4 do `verifica.sh`, no
> Athena). O grão de item teria 112.650 linhas, e 1.278 pedidos têm mais de um vendedor, o que
> multiplicaria a contagem de pedidos (`perfil_olist.json`).

## DECISÃO 02: Chave id_pedido e junção por customer_id

A chave da trusted é `id_pedido` (`order_id` da Olist). A UF de destino vem de `customers` pela
junção em `customer_id`, que tem um valor por pedido. Descartamos `customer_unique_id`, que
identifica a pessoa e se repete entre compras: usá-lo na junção duplicaria pedidos. **Aceitamos
perder** a visão por cliente recorrente, fora do escopo da pergunta. O preparo falha (em vez de
descartar em silêncio) se aparecer pedido sem cliente, chave duplicada ou fora do padrão de 32
caracteres hexadecimais.

> **Medido:** junção 1:1, com 99.441 pedidos, 99.441 clientes e 0 órfãos. `customer_unique_id`
> tem 96.096 valores distintos para 99.441 linhas (`perfil_olist.json`). Linhas de saída do
> preparo: 99.441 (`manifesto.json`).

## DECISÃO 03: Atraso compara dias, não horários

Um pedido está atrasado quando o **dia** da entrega é posterior ao **dia** previsto. A data
prevista da Olist sempre vem com hora 00:00:00, então comparar horários marcaria como atrasada
qualquer entrega feita no próprio dia prometido. **Aceitamos perder** a distinção de horas
dentro do dia, que a origem não tem para a previsão.

> **Medido:** 99.441 de 99.441 datas previstas com hora 00:00:00 (`perfil_olist.json`,
> `orders_hora_da_data_prevista`; o preparo contaria exceções em
> `prevista_com_hora_diferente_de_zero`, e a chave não aparece no manifesto porque houve 0). Pela regra de dias, 6.534
> atrasados entre 96.470 elegíveis, ou 6,77% (`manifesto.json`). Comparando horários seriam
> 7.826 (`perfil_olist.json`, `atrasados_se_comparar_timestamp`): 1.292 entregas no dia prometido
> virariam falsos atrasos, inflando a taxa em 1,34 ponto percentual.

## DECISÃO 04: Limpeza da camada bruta para a trusted e elegibilidade

O preparo (`parte-1/preparo/prepara_trusted.py`, só biblioteca padrão, 22 testes) lê o CSV com
parser de CSV, normaliza aspas, converte datas para `timestamp` e `date`, e grava um CSV sem
aspas. Entram no indicador (`elegivel = true`) os pedidos `delivered` com data de entrega. As
inconsistências de sequência entre datas são contadas, mas não excluem o pedido, porque não
envolvem as duas datas do indicador. **Aceitamos perder** os pedidos não entregues no
denominador: a taxa mede atraso de entrega, não falha de atendimento.

> **Medido** (`manifesto.json`): o `order_id` bruto vem entre aspas em 61.842 linhas e sem aspas
> em 37.599 (um leitor ingênuo quebraria a junção). Excluídos do indicador: 2.963 com status
> diferente de entregue e 8 entregues sem data, restando 96.470 elegíveis. Anomalias mantidas e
> contadas: 166 coletas antes da compra, 1.359 coletas antes da aprovação, 23 entregas antes da
> coleta, 14 entregues sem aprovação, 2 entregues sem coleta e 6 cancelados com data de entrega.
> Duplicatas: 0 (nenhuma deduplicação inventada). No Athena,
> `count_if(motivo_exclusao IS NULL) = 96470`, confirmando que o campo vazio vira nulo (critério
> 4 do `verifica.sh` em `evidencias/execucao-20261002T001732Z/11-verificacao.txt`).

## DECISÃO 05: Período da pergunta de 2017-01 a 2018-08

A pergunta usa compras de 01/01/2017 até 31/08/2018 (20 meses completos). As bordas da base são
quase vazias e distorceriam comparações. **Aceitamos perder** os poucos pedidos de 2016. O
filtro fica na consulta, não na trusted, que mantém toda a base.

> **Medido:** pedidos por mês de compra nas bordas (`perfil_olist.json`,
> `orders_por_mes_compra`): 2016-09 = 4, 2016-10 = 324, 2016-11 = 0, 2016-12 = 1, 2018-09 = 16,
> 2018-10 = 4. No período: 96.203 dos 96.470 elegíveis; ficam de fora 267 elegíveis de 2016 e
> nenhum de 2018-09 ou 2018-10 (`perfil_olist.json`, `atraso_por_mes_compra`). Todas as 27 UFs
> têm ao menos 40 pedidos elegíveis no período (`manifesto.json`, `pergunta_referencia`).

## DECISÃO 06: Formato CSV sem aspas (LazySimpleSerDe)

A trusted é um CSV com cabeçalho, vírgula, sem aspas, lido pelo `LazySimpleSerDe` com
`serialization.null.format = ""` e `skip.header.line.count = 1`. Escolhemos CSV porque o
Athena varre o arquivo inteiro em formato texto, e o CSV tem menos da metade dos bytes do JSON
Lines equivalente. O CSV sem aspas só é seguro porque o preparo recusa vírgula, aspas e quebra
de linha nos campos. **Aceitamos perder** os nulos e tipos explícitos do JSON e a tolerância a
texto livre. Parquet está fora do escopo da Parte 1.

> **Medido:** CSV com 11.167.989 bytes, contra 28.693.223 bytes do mesmo conteúdo em JSON Lines
> (2,57 vezes maior, `manifesto.json`). No Athena, a pergunta varreu 11.167.989 bytes, igual ao
> tamanho do arquivo. Em JSON Lines seriam cerca de 28,7 MB varridos e US$ 0,000145 por
> consulta, contra US$ 0,00006 em CSV.

## DECISÃO 07: Partição: nenhuma na Parte 1

A tabela não é particionada. O guia exclui particionamento da AV1 (seção 4.1), e o número
mostra que aqui ele não economizaria: a pergunta lê 20 dos 25 meses com pedidos, e os meses
fora do período são quase vazios. **Aceitamos perder** a poda de leitura por mês, que fica como
dívida para a Parte 2 (Parquet particionado). Com Parquet, a meta de custo deverá ser declarada
em bytes varridos, porque o valor cobrado já está perto do mínimo de 10 MB.

> **Medido:** varredura completa de 11.167.989 bytes, cobrada como 12 MB, ou US$ 0,00006 por
> consulta. Uma partição por mês de compra podaria só os 349 pedidos fora do período (0,35% das
> 99.441 linhas). Pela estimativa proporcional às linhas, a leitura cairia para cerca de 11,13 MB,
> ainda cobrados como 12 MB: economia zero. Mesmo uma poda perfeita esbarraria no mínimo de
> 10 MB (no máximo 2 MB, ou 16,7%, de economia).

## DECISÃO 08: Custo por consulta e teto do workgroup

O custo de cada consulta é medido pelo `DataScannedInBytes` da execução (`get-query-execution`)
e calculado como `max(MB arredondado para cima, 10 MB) x US$ 5,00 / TB`, com 1 MB = 10^6 bytes e
1 TB = 10^12 bytes (preço do Athena em us-east-1, consultado em 01/10/2026). É um custo
calculado, não o valor da fatura. O workgroup impõe sua configuração e cancela consultas que
leiam mais de 52.428.800 bytes (50 MiB) do S3. O teto conta bytes **lidos**, não o tamanho de
resultados intermediários: ele pega erros como uma tabela cujo `LOCATION` aponte por engano para
um prefixo com muito mais dados, ou uma consulta que leia a tabela 5 vezes ou mais. Uma junção
da tabela com ela mesma lê cerca de 22,3 MB (2 varreduras), passa pelo teto e é cobrada por
esses bytes (cerca de US$ 0,00012); o risco dela é tempo de execução, não custo. **Aceitamos
perder** consultas legítimas que precisem ler mais de 4,69 varreduras completas da tabela, que a
pergunta desta parte não exige.

> **Medido:** na execução registrada, pergunta com estado `SUCCEEDED`, 11.167.989 bytes
> varridos, 945 ms de motor e custo calculado de US$ 0,0000600000 (12 MB cobrados; execução
> `dec4ad26-b1c2-4bd7-831c-614dce443259`, em
> `evidencias/execucao-20261002T001732Z/consulta-execucao.txt`). A mesma consulta varreu os
> mesmos 11.167.989 bytes na verificação (execução `81a52669-6f54-47c5-bfd9-3ad910424826`) e em
> desenvolvimento (execução `145bae2d-8639-454c-b711-e1a550bd64c1`). O teto de 52.428.800 bytes
> vale 4,69 vezes a varredura completa: a pergunta usa 21% dele, e só leituras acima de 4,69
> varreduras são canceladas.

## DECISÃO 09: Carga dos dados via aws_s3_object

Os arquivos bruto e trusted são enviados ao S3 por `aws_s3_object` no próprio Terraform, com
`source_hash = filemd5(...)`. O guia exige a plataforma 100% em Terraform e o destroy sem órfão:
com a carga no Terraform, o `apply` sobe dados e infraestrutura juntos, e o `destroy` apaga os
objetos sem passo manual. Os labs usavam `aws s3 cp` fora do Terraform, o que deixaria dados
fora do state. **Aceitamos perder** repositório leve: os dados ficam versionados no git.

> **Medido:** 3 objetos, com 17.654.914 + 9.033.957 + 11.167.989 = 37.856.860 bytes. O
> `terraform apply` da raiz cria 13 recursos, incluindo os 3 objetos, e o `destroy` remove os 13
> (`evidencias/execucao-20261002T001732Z/08-apply.txt` e `12-destroy.txt`). O pós-destroy
> encontra 0 buckets do grupo (`14-pos-destroy.txt`). Após o apply, `plan -detailed-exitcode`
> devolve 0 (nada a reenviar; critério 2 em `11-verificacao.txt`).

## DECISÃO 10: Backend com bootstrap, trava DynamoDB e workspace av1

O backend remoto (S3 versionado + DynamoDB) é criado por uma stack separada,
`parte-1/bootstrap`, com state local, para que nada precise existir na conta antes do deploy.
A raiz usa o workspace `av1`, e uma precondição bloqueia o `default` para não misturar states.
Os nomes seguem o padrão fixo do guia (`eda262-g02-*`), então só um workspace pode estar
aplicado por vez. **Aceitamos** o aviso de depreciação do `dynamodb_table` no Terraform atual,
porque o guia exige DynamoDB, e a ordem obrigatória do destroy: primeiro a raiz, depois o
bootstrap.

> **Medido** (`evidencias/execucao-20261002T001732Z/`): bootstrap com 5 recursos
> (`04-bootstrap-apply.txt`) e raiz com 13 (`08-apply.txt`); ciclo completo do zero ao
> pós-destroy em 3 min 29 s. State em
> `s3://eda262-g02-tfstate/eda262-g02/av1/parte-1/terraform.tfstate` com 28.946 bytes após o
> apply (`09-state-remoto.txt`). `plan` no workspace `default` termina com
> `Error: Resource precondition failed` e código 1 (`06-workspace-default-bloqueado.txt`); no
> `av1`, `plan -detailed-exitcode` devolve 0 após o apply (critério 2 em `11-verificacao.txt`).

## Observação: tags obrigatórias

As tags `turma=eda262`, `grupo=g02` e `projeto=engenharia-de-dados` são aplicadas por
`default_tags` no provider (mais `workspace=av1` na raiz). Dois tipos de recurso não aceitam tags
na API da AWS e ficam sem elas: a tabela do Glue (`aws_glue_catalog_table`) e a consulta salva do
Athena (`aws_athena_named_query`). Os dois são removidos pelo destroy junto com o database e o
workgroup.

> **Medido:** o critério 6 do `verifica.sh` confere as três tags em 8 recursos: os 4 buckets, o
> workgroup, o Glue database, a tabela de trava e o objeto trusted.
