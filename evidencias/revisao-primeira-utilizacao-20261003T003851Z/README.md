# Revisão de primeira utilização (02/10/2026, horário local; 03/10 em UTC)

Execução do projeto do zero, como uma pessoa que nunca o usou, seguindo o `README.md` ao pé da
letra. A execução partiu de um clone limpo do commit `7777c3c`, numa pasta fora do OneDrive e sem
cache de providers do Terraform.
Cada arquivo traz: objetivo e relação com o guia, diretório, comando exato, horários (UTC), saída
completa e código de saída. O ID da conta AWS foi substituído por `<ACCOUNT_ID>`. Os códigos de cor
do Terraform foram mantidos como saíram (o registro desta revisão não os remove).
As confirmações interativas de `apply` e `destroy` foram respondidas com `yes` pela entrada
padrão, como o README orienta; não foi usado `-auto-approve`.

| Etapa | Objetivo | Código de saída |
| --- | --- | --- |
| `01-contexto-clone.txt` | Registrar a versão exata revisada e confirmar que o clone está limpo (isolamento) | 0 |
| `02-pre-requisitos.txt` | README, seção Pré-requisitos: Terraform >= 1.6, AWS CLI v2, bash, Python >= 3.10 | 0 |
| `03-credenciais.txt` | README, passo 0: credenciais do grupo exportadas (AWS_PROFILE) e região us-east-1 | 0 |
| `04-dados-brutos-hash.txt` | Guia 3 (dados do cenário): conferir que os CSVs brutos versionados são os originais (hashes do FONTE.md) | 0 |
| `05-preparo-trusted.txt` | Guia 4.1 (trusted modelada) e Guia 3 (sujeira bruta para confiável): regenerar a trusted e conferir que sai idêntica a versionada | 0 |
| `06-testes-preparo.txt` | README, Dados e licença: testes do preparo (regras de atraso, elegibilidade, falhas explícitas, determinismo, números da EDA) | 0 |
| `07-testes-scripts.txt` | README, Execução registrada: testes dos scripts bash com aws e terraform falsos (nulos, região fixa, limpeza em falha) | 0 |
| `08-terraform-fmt.txt` | Qualidade do IaC: formatação canônica de todos os .tf | 0 |
| `09-eda-no-clone.txt` | Reprodutibilidade da EDA (exploracao/) a partir apenas do repositório | 0 |
| `10-eda-com-dataset.txt` | Reprodutibilidade dos números da EDA citados no DECISOES.md: rodar a EDA numa cópia isolada com o dataset original do Kaggle e comparar com o perfil versionado | 0 |
| `11-readme-passo1-conta-limpa.txt` | README passo 1 / Guia 06 (conta limpa): confirmar que a conta não tem recursos do grupo antes do deploy | 0 |
| `12-readme-passo2-bootstrap-init.txt` | README passo 2 / Guia 4.1 (backend remoto): init da stack de backend; baixa o provider fixado no lock | 0 |
| `13-readme-passo2-bootstrap-apply.txt` | README passo 2 / Guia 4.1: criar bucket de state e tabela de trava DynamoDB (confirmação interativa respondida com yes) | 0 |
| `14-readme-passo3-init.txt` | README passo 3 / Guia 4.1 (backend S3 + DynamoDB): init da raiz configurando o backend remoto | 0 |
| `15-readme-passo3-workspace.txt` | README passo 3 / Guia 4.1 (workspace): criar e selecionar o workspace av1 | 0 |
| `16-terraform-validate.txt` | Qualidade do IaC: validar a configuração da raiz e do backend | 0 |
| `17-readme-passo4-apply.txt` | README passo 4 / Guia 4.1: provisionar o Data Lake (buckets, objetos, Glue, workgroup, consulta salva) no workspace av1 | 0 |
| `18-readme-passo5-consulta.txt` | README passo 5 / Guia 4.1 (pergunta no Athena com custo medido): executar a pergunta e medir bytes e custo | 0 |
| `19-readme-passo6-verifica.txt` | README passo 6 / Guia 06 (verifica.sh PASSA/FALHA): verificação de aceite com a stack aplicada | 0 |
| `20-sonda-tags.txt` | Guia 5 (tags obrigatórias em todo recurso): inventário independente de tags de cada recurso do grupo, inclusive os objetos raw que o verifica não confere | 0 |
| `21-sonda-glue-tabela.txt` | Guia 4.1 (schema declarado no IaC, trusted com grão): definição real da tabela no Glue Data Catalog | 0 |
| `22-sonda-workgroup.txt` | Guia 4.1 (workgroup do Athena) e DECISÃO 08 (teto): configuração real do workgroup | 0 |
| `23-sonda-buckets.txt` | Segurança e destroy: bloqueio público dos 4 buckets; versionamento e criptografia do bucket de state | 0 |
| `24-sonda-objetos-s3.txt` | DECISÃO 09 (carga via aws_s3_object): objetos no S3 batem com os arquivos locais (tamanho e MD5/ETag) | 0 |
| `25-sonda-consulta-salva.txt` | Pergunta registrada no IaC: a consulta salva no workgroup é idêntica ao pergunta.sql | 1 |
| `26-sonda-consulta-salva-corrigida.txt` | Refazer a etapa 25 sem o artefato de comparação (a saída text da CLI acrescenta uma quebra de linha final): comparar o conteúdo ignorando espaços em branco finais | 0 |
| `27-sonda-conteudo-trusted-s3.txt` | DECISÃO 09: o objeto trusted no S3 tem exatamente os bytes do arquivo versionado (SHA-256 do download) | 0 |
| `28-sonda-regra-atraso-athena.txt` | DECISÕES 03 e 04 recalculadas no próprio Athena a partir das colunas de data: flag persistida x regra por dia x comparação por horário; exclusões por motivo | 0 |
| `29-sonda-regra-atraso-athena-corrigida.txt` | Refazer a etapa 28 (SQL em arquivo): DECISÕES 03 e 04 recalculadas no Athena a partir das colunas de data e exclusões por motivo | 0 |
| `30-conferencia-por-uf.txt` | Pergunta respondida corretamente: comparar as 27 linhas do resultado do Athena (passo 5) com o cálculo local independente do preparo, UF a UF | 1 |
| `31-conferencia-por-uf-corrigida.txt` | Refazer a etapa 30 (script em arquivo): comparar as 27 linhas do Athena com o cálculo local do preparo, UF a UF | 0 |
| `32-readme-destroy1-raiz.txt` | README Destroy passo 1 / Guia 4.1 (destroy limpo): destruir o Data Lake (confirmação interativa respondida com yes) | 0 |
| `33-readme-destroy2-backend.txt` | README Destroy passo 2: destruir o backend por último (guarda o state da etapa anterior) | 0 |
| `34-readme-destroy3-pos-destroy.txt` | README Destroy passo 3 / Guia 06 (recurso órfão reprova): conferir que não restou recurso do grupo | 0 |
| `35-analise-complementar.txt` | Revisão crítica (seção 4 do pedido): IC de 95% das taxas, prazo prometido x real, sensibilidade a exclusão dos não entregues e concentração temporal; a partir da trusted versionada, sem alterar resultados oficiais | 0 |

Observações honestas sobre o registro:

- As etapas 25, 28 e 30 falharam por defeito das **checagens da revisão**, não do projeto:
  - 25: a saída `text` da AWS CLI acrescenta uma quebra de linha final;
  - 28: um escape `\x27` dentro de aspas duplas não virou aspa simples, e o SQL saiu malformado;
  - 30: escapes de aspas dentro de uma f-string do Python.
- Elas foram refeitas como 26, 29 e 31, com os resultados corretos.
- A etapa 28 registrou código 0 porque o último comando do bloco terminou bem. Os erros estão
  na saída do arquivo.
- A etapa 09 mostra que a EDA não roda só com o repositório (o dataset completo do Kaggle não é
  versionado). A etapa 10 mostra que, com o dataset, ela regenera exatamente o perfil versionado.
- `artefatos/` guarda o `consulta-execucao.txt` e o `consulta-resultado.csv` produzidos pelo
  passo 5 do README.
