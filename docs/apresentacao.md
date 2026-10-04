# Apresentação da Parte 1 (AV1), grupo g02: roteiro dos slides

Fonte para montar os slides em outra plataforma e exportar como `apresentacao-parte-1-g02.pdf`
(nome exigido pelo guia, seção 5).

- **Tempo:** 5 minutos, interrompidos no limite, mais 2 minutos de perguntas (guia, seção 7).
- **Origem dos números:** todos foram verificados em `evidencias/ciclo-completo/`,
  `DECISOES.md` e `exploracao/saida/analise_revisao.json`.
- **Prints:** as capturas indicadas (P1 a P6) estão descritas em `docs/roteiro-demonstracao.md`.

## Diretriz visual (guia, seção 7)

- **Texto:** fonte Arial; um título por slide; no máximo 5 tópicos e uma ideia central por slide.
- **Cor:** laranja só em acentos; marcadores quadrados; sem 3D, sombras ou imagens genéricas.
- **Destaques:** números e palavras-chave. Gráficos monocromáticos, com a série principal em laranja.

## O que o guia pede que a apresentação cubra

| Item do guia (seção 7) | Slides |
| --- | --- |
| Cenário e pergunta de negócio | 1 e 2 |
| Arquitetura provisionada (Terraform, backend) | 3 |
| Demonstração: apply, consulta no Athena, custo medido e destroy | 3, 5 e 8 |
| Decisões de engenharia com número (grão, chaves, partição, formato, custo) | 4 e 7 |

## Distribuição do tempo

| Slide | Tema | Tempo | Acumulado |
| ---: | --- | ---: | ---: |
| 1 | Pergunta de negócio | 0:25 | 0:25 |
| 2 | Dados e sujeira real | 0:35 | 1:00 |
| 3 | Arquitetura em Terraform | 0:45 | 1:45 |
| 4 | Trusted, grão e regra de atraso | 0:35 | 2:20 |
| 5 | Demonstração: consulta e custo | 0:50 | 3:10 |
| 6 | Resultados | 0:45 | 3:55 |
| 7 | Decisões com número | 0:40 | 4:35 |
| 8 | Destroy e conclusão | 0:25 | 5:00 |

---

## Slide 1: Onde a promessa de entrega mais falha?

- Marketplace promete uma **data de entrega**; parte dos pedidos chega depois
- Pergunta: **em quais estados** a promessa foi mais descumprida, de jan/2017 a ago/2018?
- Resposta em **quantidade** e **taxa** de pedidos entregues após a data prevista
- Data Lake **100% em Terraform**, respondendo no **Athena** com **custo medido**

> Fala (25 s): o problema de negócio e por que olhar quantidade e taxa juntas. A quantidade mostra
> quantos clientes foram afetados; a taxa, a intensidade do problema.

## Slide 2: Dados públicos da Olist, com sujeira real

- **99.441 pedidos** reais e anonimizados, de 2016 a 2018 (Kaggle, licença CC BY-NC-SA 4.0)
- Dois arquivos: pedidos (status e datas) e clientes (UF de destino); junção **1:1, 0 órfãos**
- Aspas inconsistentes no `order_id`: **61.842** com aspas e **37.599** sem
- **8** entregues sem data de entrega; **166** coletas antes da compra
- **0** duplicatas: nada foi inventado para limpar

> Fala (35 s): a sujeira do guia (camada bruta para a confiável) existe de verdade na base.

## Slide 3: Arquitetura provisionada do zero

- Diagrama (desenhar): CSV bruto → preparo (Python) → S3 `lake-raw` e `lake-trusted` → Glue
  (schema declarado, sem Crawler) → Athena (workgroup com teto)
- **Bootstrap**: bucket de state + trava **DynamoDB** (5 recursos)
- **Módulo `lake`** no workspace **`av1`**: 13 recursos, inclusive a carga dos dados
- Tags `turma`, `grupo`, `projeto` em todos os recursos que aceitam tags

> **Print P2** (`Apply complete! Resources: 13 added`) no canto do slide.

> Fala (45 s): por que um bootstrap separado (o bucket do state precisa existir antes do backend)
> e por que o workspace `default` é bloqueado.

## Slide 4: Trusted com grão de um pedido

- Grão: **1 linha = 1 pedido**; chave `id_pedido`; **99.441 = 99.441** distintos
- Atraso: **dia** da entrega maior que o **dia** previsto
- Comparar horário daria **7.826** atrasos em vez de **6.534**: **1.292** falsos atrasos
- Elegíveis: **96.470** entregues com data; 2.963 não entregues ficam fora do indicador

> Fala (35 s): a data prevista sempre vem às 00:00. Por isso a comparação é por dia.

## Slide 5: Demonstração, consulta no Athena com custo

- **Print P4**: saída do `consulta.sh`, com `estado=SUCCEEDED`, `bytes_varridos=11167989` e
  `custo_calculado_usd=0.0000600000`
- Custo: 11,2 MB lidos, cobrados como **12 MB** (mínimo de 10 MB) x US$ 5/TB = **US$ 0,00006**
- **Print P5**: `verifica.sh` com **7 de 7 critérios PASSA**

> Fala (50 s): o que é o custo medido (bytes varridos da execução, não estimativa) e que o
> `verifica.sh` confere todos os requisitos na própria conta AWS.

## Slide 6: Resultados

Gráfico de barras com os atrasados por UF (top 10), série principal em laranja:

| UF | SP | RJ | MG | BA | RS | SC | ES | PR | CE | PE |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Atrasados | 1.817 | 1.495 | 519 | 396 | 325 | 291 | 214 | 199 | 176 | 153 |
| Taxa (%) | 4,50 | 12,14 | 4,59 | 12,17 | 6,10 | 8,23 | 10,74 | 4,06 | 13,83 | 9,64 |

- **SP**: mais atrasos (1.817), com taxa baixa (4,5%)
- **RJ**: volume **e** taxa altos (1.495; 12,1%): **prioridade de investigação**
- **AL**: maior taxa (21,5%), mas só 396 pedidos
- **1.699** pedidos nunca entregues com prazo vencido: o ranking por volume **não muda**

> Fala (45 s): a taxa mede promessa cumprida, não velocidade (a promessa varia por UF). Se o
> professor perguntar sobre AL contra MA: os intervalos de confiança se sobrepõem.

## Slide 7: Decisões com número

- **Formato CSV**: 11,2 MB contra 28,7 MB em JSON Lines (**2,57x** menos bytes lidos)
- **Sem partição** (fora de escopo da AV1): podaria só **0,35%** das linhas; custo igual (12 MB)
- **Teto do workgroup**: 50 MiB = **4,69** varreduras completas; a pergunta usa 21%
- **Carga via Terraform** (`aws_s3_object`): o destroy apaga os dados junto
- **Custo**: calculado dos bytes medidos, não da fatura

> Fala (40 s): cada decisão tem o número que a sustenta no `DECISOES.md`.

## Slide 8: Destroy limpo e conclusão

- **Print P6**: `Destroy complete! Resources: 13 destroyed` e `5 destroyed`; pós-destroy com
  **0 recursos** do grupo
- Sobe do zero, responde à pergunta, mede o custo e não deixa órfão
- Tudo reproduzível: trusted com o mesmo SHA-256 e 27 de 27 UFs iguais ao cálculo local
- Próximo passo (AV2): Parquet particionado, camadas e ingestão idempotente

> Fala (25 s): fechar com a resposta da pergunta (SP e RJ por volume; RJ por volume e taxa).

---

## Para os 2 minutos de perguntas (não é slide)

O docente pode sortear uma decisão e pedir que um integrante a explique. As justificativas, com o
número de cada decisão, estão no `DECISOES.md`. Todos do grupo devem conhecer pelo menos:

- grão e chave (1 pedido; 99.441 = 99.441; junção 1:1);
- regra por dia (1.292 falsos atrasos evitados);
- formato (2,57x);
- partição (0,35%; custo igual);
- custo (US$ 0,00006, com mínimo de 10 MB);
- teto (4,69x);
- bootstrap e workspace;
- destroy sem órfão.
