# Apresentação da Parte 1 (AV1), grupo g02: roteiro dos slides

Este arquivo é a fonte para montar os slides em outra plataforma e exportar como
`apresentacao-parte-1-g02.pdf` (nome exigido pelo guia, seção 5).

Cada slide tem duas partes:
- **Tópicos do slide:** o que aparece na tela, curto.
- **Texto para ler:** o que se fala, explicativo, com o tempo e a quantidade de palavras.

O texto todo tem cerca de 650 palavras: a 140 palavras por minuto, são cerca de 4 min 40 s de
fala, com uns 20 segundos de folga para as trocas de slide. Ensaiem com cronômetro: aos 5 minutos a
apresentação é interrompida. Cada slide indica o que pode ser cortado se o tempo apertar.

- **Números:** todos foram verificados em `evidencias/ciclo-completo/`, `DECISOES.md` e
  `exploracao/saida/analise_revisao.json`.
- **Prints:** as capturas P0 a P7 estão descritas em `docs/roteiro-demonstracao.md`.

## O que o guia exige (seção 7) e onde está

A ordem dos slides segue os quatro itens que a apresentação precisa cobrir:

| Item exigido pelo guia | Slides | Tempo |
| --- | --- | ---: |
| 1. O cenário e a pergunta de negócio que a plataforma responde | 1 | 0:40 |
| 2. A arquitetura provisionada: o que sobe e como (Terraform, backend; camadas só na Parte 2) | 2 | 0:50 |
| 3. A demonstração: apply do zero ou evidência gravada, a consulta respondida no Athena, o custo medido e o destroy | 3 a 6 | 2:05 |
| 4. As decisões de engenharia: grão, chaves, partição, formato e custo, cada uma com número | 7 | 1:10 |
| Fechamento | 8 | 0:15 |
| **Total** | | **5:00** |

Como a apresentação é avaliada (seção 7, compõe 15% da nota):

| Critério | Peso | Onde se ganha |
| --- | ---: | --- |
| Clareza e tempo: mensagem objetiva e completa em 5 minutos | 3 | ensaiar com cronômetro; um slide, uma ideia |
| Demonstração: apply, consulta com custo e destroy funcionando ou evidenciados | 5 | slides 3 a 6, com prints reais |
| Decisões com número: cada escolha comprovada com valor medido | 4 | slide 7 |
| Defesa individual: o integrante sorteado defende uma decisão | 3 | seção final deste arquivo |

**Demonstração ao vivo ou gravada?** O guia aceita "apply do zero ou evidência gravada". Fazer
apply e destroy ao vivo não cabe em 5 minutos: só o apply leva cerca de 1 minuto, e a rede pode
atrasar. A recomendação é usar os prints do roteiro de demonstração.

Se quiserem um trecho ao vivo:
1. Subam a stack antes da aula.
2. Na apresentação, rodem só o `consulta.sh`, que leva cerca de 20 segundos.
3. Mostrem o destroy por print.
4. Destruam a stack logo depois da aula.

## Diretriz visual (guia, seção 7)

- **Texto:** fonte Arial; um título por slide; no máximo 5 tópicos e uma ideia central por slide.
- **Cor:** laranja com parcimônia, só em acentos; marcadores quadrados.
- **Proibido:** 3D, sombras e banco de imagens genérico.
- **Destaques:** números e palavras-chave. Gráficos monocromáticos, com a série principal em laranja.

---

## Item 1: cenário e pergunta

### Slide 1: Onde a promessa de entrega mais falha? (0:40)

**Tópicos do slide**

- Marketplace promete uma **data de entrega**; parte dos pedidos chega depois
- Dados: **99.441 pedidos** reais da Olist (2016 a 2018, dataset público)
- Pergunta: **em quais estados** a promessa foi mais descumprida, de jan/2017 a ago/2018?
- Resposta por UF: **quantidade** e **taxa** de pedidos entregues após a data prevista

**Texto para ler** (cerca de 90 palavras)

> Nosso cenário é um marketplace de comércio eletrônico. Em cada compra, o cliente recebe uma data
> prevista de entrega, que funciona como uma promessa. Usamos o dataset público da Olist, com 99.441
> pedidos reais de 2016 a 2018. A pergunta que a nossa plataforma responde é: em quais estados a
> promessa de prazo foi mais descumprida entre janeiro de 2017 e agosto de 2018? Respondemos com duas
> medidas por estado: a quantidade de atrasos, que mostra quantos clientes foram afetados, e a taxa,
> que mostra a intensidade do problema.

## Item 2: arquitetura provisionada

### Slide 2: O que sobe e como (0:50)

**Tópicos do slide**

Diagrama (desenhar):

```
CSV bruto -> preparo (Python) -> S3 lake-raw / lake-trusted -> Glue (schema declarado) -> Athena (workgroup com teto)
```

- **100% Terraform**, em duas stacks: `bootstrap` (bucket de state + trava **DynamoDB**, 5 recursos)
  e raiz com o **módulo `lake`** (13 recursos)
- **Backend remoto S3 + DynamoDB** e workspace **`av1`** (o `default` é bloqueado)
- O módulo cria os buckets e **carrega os dados**; também cria o **Glue** (10 colunas declaradas,
  sem Crawler) e o **workgroup** do Athena
- Camadas: bruta e **trusted** nesta parte; refined e permissões por camada ficam para a Parte 2
- Preparo limpa a camada bruta: aspas inconsistentes no `order_id` (**37.599** sem aspas), datas em
  texto, 8 entregues sem data

> Print opcional P3 (plan no workspace `default` bloqueado), se sobrar espaço.

**Texto para ler** (cerca de 110 palavras)

> Toda a infraestrutura é 100% Terraform e sobe em duas etapas. Primeiro, uma stack de bootstrap cria
> o backend remoto: um bucket S3 versionado, que guarda o state, e uma tabela DynamoDB que trava o
> state, para que duas pessoas não apliquem ao mesmo tempo. Depois, a configuração principal usa esse
> backend, roda no workspace av1 e chama o módulo lake. O módulo cria 13 recursos: os buckets da
> camada bruta, da trusted e dos resultados, a carga dos dados, o banco e a tabela no Glue, com as 10
> colunas declaradas no código, sem Crawler, e o workgroup do Athena. A camada refined fica para a
> Parte 2.

*Se o tempo apertar:* corte a última frase (camada refined).

## Item 3: demonstração (evidência gravada)

### Slide 3: Apply do zero (0:30)

**Tópicos do slide**

- **Print P0**: conta sem nenhum recurso do grupo (`1 de 1 criterios PASSA`)
- **Print P1**: backend criado, com `Apply complete! Resources: 5 added`
- **Print P2**: Data Lake criado, com `Apply complete! Resources: 13 added` e os outputs

**Texto para ler** (cerca de 60 palavras)

> Agora a demonstração, com evidência gravada. Primeiro, conferimos que a conta não tinha nenhum
> recurso do grupo. Em seguida, o apply do backend criou 5 recursos, e o apply do Data Lake criou
> mais 13, com os dados já carregados no S3. Nada foi criado à mão: tudo sai do código, numa conta
> limpa.

### Slide 4: A consulta respondida no Athena (0:45)

**Tópicos do slide**

- **Print P4**: saída do `consulta.sh`, com `estado=SUCCEEDED` e as primeiras UFs
- Tabela (destacar RJ em laranja):

| UF | Atrasados | Taxa |
| --- | ---: | ---: |
| SP | 1.817 | 4,5% |
| **RJ** | **1.495** | **12,1%** |
| MG | 519 | 4,6% |
| BA | 396 | 12,2% |
| RS | 325 | 6,1% |

- **RJ** junta volume e taxa altos: prioridade de investigação
- Maior taxa: **AL** (21,5%), mas sobre só 396 pedidos
- **1.699** pedidos sem entrega com prazo vencido ficam fora do indicador; o ranking por volume
  não muda

**Texto para ler** (cerca de 105 palavras)

> Com a infraestrutura de pé, rodamos a pergunta no Athena. A consulta terminou com sucesso e
> devolveu os 27 estados. São Paulo tem o maior número de atrasos, 1.817, mas com taxa baixa, de
> 4,5%, porque recebe muitos pedidos. O Rio de Janeiro é o caso mais importante: tem o segundo maior
> volume, 1.495 atrasos, e uma taxa de 12,1%, quase três vezes a de São Paulo. Por isso é a
> prioridade de investigação. Alagoas tem a maior taxa, 21,5%, mas sobre apenas 396 pedidos. Uma
> ressalva: 1.699 pedidos ficaram sem entrega registrada e fora do indicador, mas contá-los não muda
> o ranking por volume.

*Se o tempo apertar:* corte a frase sobre Alagoas.

### Slide 5: O custo medido (0:30)

**Tópicos do slide**

- Bytes lidos pela consulta (`DataScannedInBytes`): **11.167.989**
- Cobrança: arredondado para cima e mínimo de 10 MB, ou seja, **12 MB** x US$ 5 por TB =
  **US$ 0,00006** por consulta
- Teto do workgroup: 50 MiB por consulta (a pergunta usa 21%)
- **Print P5**: `verifica.sh` com **7 de 7 critérios PASSA**

**Texto para ler** (cerca de 60 palavras)

> O custo vem do número de bytes que o próprio Athena registrou na execução: 11.167.989 bytes. O
> Athena cobra 5 dólares por terabyte lido, arredondando para cima, com mínimo de 10 MB por
> consulta. Então foram cobrados 12 MB, o que dá 0,00006 dólar por consulta, ou seis cem-milésimos
> de dólar. E o script de verificação passou nos 7 critérios de aceite.

### Slide 6: Destroy sem órfão (0:20)

**Tópicos do slide**

- **Print P6**: `Destroy complete! Resources: 13 destroyed` e `5 destroyed`
- Pós-destroy: **0** buckets, bancos, workgroups e tabelas do grupo
- Ordem: primeiro o Data Lake, depois o backend (que guarda o state)

**Texto para ler** (cerca de 45 palavras)

> Por fim, o destroy. Primeiro destruímos o Data Lake, 13 recursos, e depois o backend, 5 recursos,
> nessa ordem, porque é o backend que guarda o state. A verificação final confirmou que não sobrou
> nenhum bucket, banco, workgroup ou tabela do grupo na conta.

## Item 4: decisões de engenharia com número

### Slide 7: Grão, chaves, partição, formato e custo (1:10)

**Tópicos do slide**

- **Grão**: 1 linha = 1 pedido; **99.441** linhas = **99.441** pedidos distintos
- **Chaves**: `id_pedido`, único e sem nulos; junção por `customer_id` **1:1**, com **0 órfãos**
- **Partição**: nenhuma (fora do escopo da AV1); a poda por mês tiraria só **0,35%** das linhas
- **Formato**: CSV sem aspas, **11,2 MB** contra **28,7 MB** em JSON Lines (**2,57x** menos bytes)
- **Custo**: **US$ 0,00006** por consulta; teto = **4,69** leituras completas da tabela

**Texto para ler** (cerca de 150 palavras)

> Agora as decisões de engenharia, cada uma com o seu número. Grão: cada linha da tabela trusted é um
> pedido. São 99.441 linhas para 99.441 pedidos distintos. Se o grão fosse o item, seriam 112.650
> linhas, e pedidos com mais de um vendedor seriam contados várias vezes. Chaves: a chave é o
> identificador do pedido, único e sem nulos, e a junção com os clientes é um para um, sem nenhum
> registro órfão. Partição: não particionamos, porque está fora do escopo da Parte 1 e porque não
> ajudaria: a poda por mês eliminaria só 0,35% das linhas, e o custo cobrado continuaria em 12 MB.
> Formato: usamos CSV sem aspas, com 11,2 MB, contra 28,7 MB em JSON Lines. Como o Athena lê o
> arquivo inteiro, são 2,57 vezes menos bytes por consulta. Custo: seis cem-milésimos de dólar por
> consulta, com um teto que corresponde a 4,69 leituras completas da tabela.

*Se o tempo apertar:* corte a frase sobre o grão por item.

## Fechamento

### Slide 8: Conclusão (0:15)

**Tópicos do slide**

- A plataforma sobe do zero, responde à pergunta, mede o custo e é destruída sem órfão
- Resposta: **SP e RJ** concentram os atrasos; **RJ** é a prioridade (volume e taxa)
- Próximo passo, na Parte 2: Parquet particionado, camadas e ingestão idempotente

**Texto para ler** (cerca de 30 palavras)

> Concluindo: a plataforma sobe do zero, responde à pergunta, mede o custo e é destruída sem deixar
> recursos. São Paulo e Rio concentram os atrasos, e o Rio é a prioridade. Obrigado.

---

## Para a defesa individual (2 minutos de dúvidas, não é slide)

O docente pode sortear uma decisão e pedir que um integrante específico a explique (guia, seção 7).
As justificativas completas, com a medição e a fonte de cada número, estão no `DECISOES.md`. Todos
do grupo devem saber explicar, com o número:

| Decisão | Número para citar |
| --- | --- |
| Grão: um pedido | 99.441 = 99.441; por item seriam 112.650 linhas |
| Chaves e junção | junção 1:1, 0 órfãos; `customer_unique_id` tem 96.096 valores |
| Atraso compara dias, não horários | 6.534 atrasados contra 7.826: 1.292 falsos atrasos evitados |
| Elegibilidade (só entregues) | 2.963 não entregues e 8 sem data excluídos; os 1.699 vencidos não mudam o ranking por volume |
| Período 2017-01 a 2018-08 | bordas com 4, 0, 1, 16 e 4 pedidos por mês |
| Formato CSV | 2,57x menos bytes que JSON Lines |
| Sem partição | 0,35% de poda; custo igual (12 MB) |
| Custo e teto | US$ 0,00006; teto de 50 MiB = 4,69 varreduras |
| Carga via Terraform | 3 objetos, 37,9 MB; o destroy apaga os dados junto |
| Backend, bootstrap e workspace | 5 + 13 recursos; o `plan` no `default` falha com código 1 |
