# Verificações complementares

As checagens foram feitas em 03/10/2026, entre 00:42 e 00:52 UTC, com a stack aplicada a partir do
commit `7777c3c`. Os arquivos de Terraform e de dados são os mesmos da versão publicada. Elas
comprovam o que o `verifica.sh` não cobre.

Cada arquivo traz:
- o objetivo;
- o comando exato;
- a saída completa;
- o código de saída.

O ID da conta foi substituído por `<ACCOUNT_ID>`, e os caminhos locais por `<raiz-do-projeto>` e
`<pasta-temporaria>`.

Nos comandos, os textos estão sem acento, porque foram digitados no shell. Os arquivos foram
renomeados para nomes descritivos; o conteúdo não foi alterado, exceto pela troca dos caminhos
locais.

| Arquivo | O que comprova | Resultado | Relação |
| --- | --- | --- | --- |
| `tags-dos-recursos.txt` | inventário de tags pela API de tags da AWS e nos objetos brutos | os 7 recursos que aceitam tags e os objetos brutos têm `turma`, `grupo` e `projeto`; a tabela do Glue não tem tags | guia, seção 5 (tags) |
| `definicao-da-tabela-glue.txt` | definição real da tabela no Glue Data Catalog | `EXTERNAL_TABLE`, LazySimpleSerDe, `skip.header.line.count=1`, `serialization.null.format=""`, as 10 colunas e os tipos do código | guia 4.1 (schema no IaC) |
| `configuracao-do-workgroup.txt` | configuração real do workgroup | `EnforceWorkGroupConfiguration=true`, teto de 52.428.800 bytes, resultados criptografados, engine v3 | DECISÃO 08 |
| `integridade-do-objeto-trusted.txt` | o arquivo trusted no S3 é idêntico ao versionado | mesmo SHA-256 (`de2bb699...`) no download e no repositório | DECISÃO 09 |
| `regra-de-atraso-no-athena.txt` | regra de atraso recontada no Athena a partir das colunas de data | 96.470 elegíveis; 6.534 atrasados pela coluna e pela regra por dia; 7.826 se comparasse horários; 0 inconsistências; exclusões de 2.963 e 8 | DECISÕES 03 e 04 |
| `resultado-por-uf.txt` | as 27 linhas do Athena contra o cálculo local, UF a UF | 0 divergências | pergunta respondida corretamente |
| `reproducao-da-eda.txt` | a análise exploratória, com o dataset completo do Kaggle, regenera exatamente o perfil versionado | `perfil regenerado identico ao versionado: True` | números da EDA citados no DECISOES.md |

Esses arquivos foram gravados por um script auxiliar da revisão, que não faz parte do projeto. Para
repetir uma checagem, basta rodar o comando registrado no próprio arquivo, com a stack aplicada.
