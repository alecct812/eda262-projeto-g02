# Apresentação da Parte 1 (AV1), grupo g02: roteiro dos slides

Este arquivo é a fonte para montar os slides em outra plataforma e exportar como
`apresentacao-parte-1-g02.pdf` (nome exigido pelo guia, seção 5).

- **Tempo:** 5 minutos de apresentação, interrompidos no limite, e 2 minutos de dúvidas.
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

- Marketplace promete uma **data de entrega**; parte dos pedidos chega depois
- Dados: **99.441 pedidos** reais da Olist (2016 a 2018, dataset público do Kaggle)
- Pergunta: **em quais estados** a promessa foi mais descumprida, de jan/2017 a ago/2018?
- Resposta por UF: **quantidade** e **taxa** de pedidos entregues após a data prevista

> Fala: quantidade mostra quantos clientes foram afetados; taxa mostra a intensidade. A equipe de
> operações precisa das duas para decidir onde investigar primeiro.

## Item 2: arquitetura provisionada

### Slide 2: O que sobe e como (0:50)

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

## Item 3: demonstração (evidência gravada)

### Slide 3: Apply do zero (0:30)

- **Print P0**: conta sem nenhum recurso do grupo (`1 de 1 criterios PASSA`)
- **Print P1**: backend criado, com `Apply complete! Resources: 5 added`
- **Print P2**: Data Lake criado, com `Apply complete! Resources: 13 added` e os outputs

> Fala: tudo sai do zero numa conta limpa; nada foi criado à mão.

### Slide 4: A consulta respondida no Athena (0:45)

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
- **1.699** pedidos nunca entregues com prazo vencido ficam fora do indicador; contá-los não muda
  o ranking por volume

> Fala: a taxa mede promessa cumprida, não velocidade; a promessa varia por UF.

### Slide 5: O custo medido (0:30)

- Bytes lidos pela consulta (`DataScannedInBytes`): **11.167.989**
- Cobrança: arredondado para cima e mínimo de 10 MB, ou seja, **12 MB** x US$ 5 por TB =
  **US$ 0,00006** por consulta
- Teto do workgroup: 50 MiB por consulta (a pergunta usa 21%)
- **Print P5**: `verifica.sh` com **7 de 7 critérios PASSA**

> Fala: o custo vem do número de bytes medido na execução, não de estimativa.

### Slide 6: Destroy sem órfão (0:20)

- **Print P6**: `Destroy complete! Resources: 13 destroyed` e `5 destroyed`
- Pós-destroy: **0** buckets, bancos, workgroups e tabelas do grupo
- Ordem: primeiro o Data Lake, depois o backend (que guarda o state)

## Item 4: decisões de engenharia com número

### Slide 7: Grão, chaves, partição, formato e custo (1:10)

- **Grão**: 1 linha = 1 pedido; **99.441** linhas = **99.441** pedidos distintos. Por item seriam
  112.650 linhas, e 1.278 pedidos com vários vendedores contariam mais de uma vez.
- **Chaves**: `id_pedido`, único e sem nulos; junção por `customer_id` **1:1**, com **0 órfãos**.
  `customer_unique_id` (96.096 valores) duplicaria pedidos.
- **Partição**: nenhuma, porque está fora do escopo da AV1. A poda por mês tiraria só **0,35%** das
  linhas, e o custo cobrado continuaria em 12 MB.
- **Formato**: CSV sem aspas, com **11,2 MB** contra **28,7 MB** em JSON Lines: **2,57x** menos
  bytes lidos.
- **Custo**: **US$ 0,00006** por consulta, com teto de 50 MiB, igual a **4,69** varreduras
  completas.

> Fala: cada número vem do `DECISOES.md`, com a fonte da medição.

## Fechamento

### Slide 8: Conclusão (0:15)

- A plataforma sobe do zero, responde à pergunta, mede o custo e é destruída sem órfão
- Resposta: **SP e RJ** concentram os atrasos; **RJ** é a prioridade (volume e taxa)
- Próximo passo, na Parte 2: Parquet particionado, camadas e ingestão idempotente

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
