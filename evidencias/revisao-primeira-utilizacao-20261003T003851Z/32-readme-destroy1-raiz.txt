# objetivo: README Destroy passo 1 / Guia 4.1 (destroy limpo): destruir o Data Lake (confirmacao interativa respondida com yes)
# diretorio: eda262-g02-revisao
# comando: printf "yes\n" | terraform -chdir=parte-1 destroy
# inicio (UTC): 2026-10-03T00:51:45Z
# ---- saida ----
[33m╷[0m[0m
[33m│[0m [0m[1m[33mWarning: [0m[0m[1mDeprecated Parameter[0m
[33m│[0m [0m
[33m│[0m [0m[0mThe parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
[33m│[0m [0minstead.
[33m╵[0m[0m
Acquiring state lock. This may take a few moments...
[0m[1mdata.aws_region.atual: Reading...[0m[0m
[0m[1mmodule.lake.aws_glue_catalog_database.this: Refreshing state... [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce][0m
[0m[1mmodule.lake.aws_s3_bucket.this["trusted"]: Refreshing state... [id=eda262-g02-lake-trusted][0m
[0m[1mdata.aws_region.atual: Read complete after 0s [id=us-east-1][0m
[0m[1mmodule.lake.aws_s3_bucket.this["resultados"]: Refreshing state... [id=eda262-g02-athena-results][0m
[0m[1mmodule.lake.aws_s3_bucket.this["raw"]: Refreshing state... [id=eda262-g02-lake-raw][0m
[0m[1mmodule.lake.aws_s3_object.trusted: Refreshing state... [id=pedidos_entrega/pedidos_entrega.csv][0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"]: Refreshing state... [id=olist/orders/olist_orders_dataset.csv][0m
[0m[1mmodule.lake.aws_athena_workgroup.this: Refreshing state... [id=eda262-g02-wg][0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"]: Refreshing state... [id=olist/customers/olist_customers_dataset.csv][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["resultados"]: Refreshing state... [id=eda262-g02-athena-results][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["trusted"]: Refreshing state... [id=eda262-g02-lake-trusted][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["raw"]: Refreshing state... [id=eda262-g02-lake-raw][0m
[0m[1mmodule.lake.aws_glue_catalog_table.pedidos_entrega: Refreshing state... [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce:pedidos_entrega][0m
[0m[1mmodule.lake.aws_athena_named_query.pergunta: Refreshing state... [id=108f917a-dfa2-40da-95c8-2ab8581b32a3][0m

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  [31m-[0m destroy[0m

Terraform will perform the following actions:

[1m  # module.lake.aws_athena_named_query.pergunta[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_athena_named_query" "pergunta" {
      [31m-[0m[0m database    = "eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
      [31m-[0m[0m description = "Pergunta da AV1: atrasos de entrega por UF de destino (2017-01 a 2018-08)" [90m-> null[0m[0m
      [31m-[0m[0m id          = "108f917a-dfa2-40da-95c8-2ab8581b32a3" [90m-> null[0m[0m
      [31m-[0m[0m name        = "eda262-g02-pergunta-atrasos-uf" [90m-> null[0m[0m
      [31m-[0m[0m query       = <<-EOT
            -- Pergunta de negocio (AV1, grupo g02): em quais estados de destino a promessa de prazo
            -- foi mais descumprida entre jan/2017 e ago/2018, considerando a quantidade e a taxa
            -- de pedidos entregues apos a data prevista?
            SELECT
              uf_cliente,
              count(*)                                               AS pedidos_elegiveis,
              count_if(atrasado)                                     AS pedidos_atrasados,
              round(100.0 * count_if(atrasado) / count(*), 2)        AS taxa_atraso_pct,
              round(avg(CASE WHEN atrasado THEN dias_atraso END), 1) AS media_dias_atraso
            FROM pedidos_entrega
            WHERE elegivel
              AND data_hora_compra >= TIMESTAMP '2017-01-01 00:00:00'
              AND data_hora_compra <  TIMESTAMP '2018-09-01 00:00:00'
            GROUP BY uf_cliente
            ORDER BY pedidos_atrasados DESC, taxa_atraso_pct DESC
        EOT [90m-> null[0m[0m
      [31m-[0m[0m workgroup   = "eda262-g02-wg" [90m-> null[0m[0m
    }

[1m  # module.lake.aws_athena_workgroup.this[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_athena_workgroup" "this" {
      [31m-[0m[0m arn           = "arn:aws:athena:us-east-1:<ACCOUNT_ID>:workgroup/eda262-g02-wg" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy = true [90m-> null[0m[0m
      [31m-[0m[0m id            = "eda262-g02-wg" [90m-> null[0m[0m
      [31m-[0m[0m name          = "eda262-g02-wg" [90m-> null[0m[0m
      [31m-[0m[0m state         = "ENABLED" [90m-> null[0m[0m
      [31m-[0m[0m tags          = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all      = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (1 unchanged attribute hidden)[0m[0m

      [31m-[0m[0m configuration {
          [31m-[0m[0m bytes_scanned_cutoff_per_query     = 52428800 [90m-> null[0m[0m
          [31m-[0m[0m enforce_workgroup_configuration    = true [90m-> null[0m[0m
          [31m-[0m[0m publish_cloudwatch_metrics_enabled = false [90m-> null[0m[0m
          [31m-[0m[0m requester_pays_enabled             = false [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m

          [31m-[0m[0m engine_version {
              [31m-[0m[0m effective_engine_version = "Athena engine version 3" [90m-> null[0m[0m
              [31m-[0m[0m selected_engine_version  = "AUTO" [90m-> null[0m[0m
            }

          [31m-[0m[0m result_configuration {
              [31m-[0m[0m output_location       = "s3://eda262-g02-athena-results/resultados/" [90m-> null[0m[0m
                [90m# (1 unchanged attribute hidden)[0m[0m

              [31m-[0m[0m encryption_configuration {
                  [31m-[0m[0m encryption_option = "SSE_S3" [90m-> null[0m[0m
                    [90m# (1 unchanged attribute hidden)[0m[0m
                }
            }
        }
    }

[1m  # module.lake.aws_glue_catalog_database.this[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_glue_catalog_database" "this" {
      [31m-[0m[0m arn          = "arn:aws:glue:us-east-1:<ACCOUNT_ID>:database/eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
      [31m-[0m[0m catalog_id   = "<ACCOUNT_ID>" [90m-> null[0m[0m
      [31m-[0m[0m description  = "Data Lake da Parte 1: atrasos de entrega de e-commerce (Olist)" [90m-> null[0m[0m
      [31m-[0m[0m id           = "<ACCOUNT_ID>:eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
      [31m-[0m[0m name         = "eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
      [31m-[0m[0m parameters   = {} [90m-> null[0m[0m
      [31m-[0m[0m tags         = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all     = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (1 unchanged attribute hidden)[0m[0m

      [31m-[0m[0m create_table_default_permission {
          [31m-[0m[0m permissions = [
              [31m-[0m[0m "ALL",
            ] [90m-> null[0m[0m

          [31m-[0m[0m principal {
              [31m-[0m[0m data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS" [90m-> null[0m[0m
            }
        }
    }

[1m  # module.lake.aws_glue_catalog_table.pedidos_entrega[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_glue_catalog_table" "pedidos_entrega" {
      [31m-[0m[0m arn                = "arn:aws:glue:us-east-1:<ACCOUNT_ID>:table/eda262_g02_entregas_ecommerce/pedidos_entrega" [90m-> null[0m[0m
      [31m-[0m[0m catalog_id         = "<ACCOUNT_ID>" [90m-> null[0m[0m
      [31m-[0m[0m database_name      = "eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
      [31m-[0m[0m description        = "Trusted: uma linha por pedido (grao), chave id_pedido" [90m-> null[0m[0m
      [31m-[0m[0m id                 = "<ACCOUNT_ID>:eda262_g02_entregas_ecommerce:pedidos_entrega" [90m-> null[0m[0m
      [31m-[0m[0m name               = "pedidos_entrega" [90m-> null[0m[0m
      [31m-[0m[0m parameters         = {
          [31m-[0m[0m "EXTERNAL"               = "TRUE"
          [31m-[0m[0m "classification"         = "csv"
          [31m-[0m[0m "skip.header.line.count" = "1"
        } [90m-> null[0m[0m
      [31m-[0m[0m retention          = 0 [90m-> null[0m[0m
      [31m-[0m[0m table_type         = "EXTERNAL_TABLE" [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m storage_descriptor {
          [31m-[0m[0m additional_locations      = [] [90m-> null[0m[0m
          [31m-[0m[0m bucket_columns            = [] [90m-> null[0m[0m
          [31m-[0m[0m compressed                = false [90m-> null[0m[0m
          [31m-[0m[0m input_format              = "org.apache.hadoop.mapred.TextInputFormat" [90m-> null[0m[0m
          [31m-[0m[0m location                  = "s3://eda262-g02-lake-trusted/pedidos_entrega/" [90m-> null[0m[0m
          [31m-[0m[0m number_of_buckets         = 0 [90m-> null[0m[0m
          [31m-[0m[0m output_format             = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat" [90m-> null[0m[0m
          [31m-[0m[0m parameters                = {} [90m-> null[0m[0m
          [31m-[0m[0m stored_as_sub_directories = false [90m-> null[0m[0m

          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "order_id da Olist; chave da tabela (grao: um pedido)" [90m-> null[0m[0m
              [31m-[0m[0m name       = "id_pedido" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "string" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "UF de destino (customer_state via customer_id)" [90m-> null[0m[0m
              [31m-[0m[0m name       = "uf_cliente" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "string" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "order_status original" [90m-> null[0m[0m
              [31m-[0m[0m name       = "status_pedido" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "string" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "order_purchase_timestamp" [90m-> null[0m[0m
              [31m-[0m[0m name       = "data_hora_compra" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "timestamp" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "order_estimated_delivery_date (sempre 00:00:00 na origem)" [90m-> null[0m[0m
              [31m-[0m[0m name       = "data_prevista_entrega" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "date" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "order_delivered_customer_date; nulo se nao entregue" [90m-> null[0m[0m
              [31m-[0m[0m name       = "data_hora_entrega" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "timestamp" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "entra no indicador: delivered com data de entrega" [90m-> null[0m[0m
              [31m-[0m[0m name       = "elegivel" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "boolean" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "dia da entrega posterior ao dia previsto; nulo se nao elegivel" [90m-> null[0m[0m
              [31m-[0m[0m name       = "atrasado" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "boolean" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "dias entre entrega e previsao (negativo = antecipado)" [90m-> null[0m[0m
              [31m-[0m[0m name       = "dias_atraso" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "int" [90m-> null[0m[0m
            }
          [31m-[0m[0m columns {
              [31m-[0m[0m comment    = "status_nao_entregue ou entregue_sem_data; nulo se elegivel" [90m-> null[0m[0m
              [31m-[0m[0m name       = "motivo_exclusao" [90m-> null[0m[0m
              [31m-[0m[0m parameters = {} [90m-> null[0m[0m
              [31m-[0m[0m type       = "string" [90m-> null[0m[0m
            }

          [31m-[0m[0m ser_de_info {
              [31m-[0m[0m name                  = "csv-sem-aspas" [90m-> null[0m[0m
              [31m-[0m[0m parameters            = {
                  [31m-[0m[0m "field.delim"               = ","
                  [31m-[0m[0m "serialization.format"      = ","
                  [31m-[0m[0m "serialization.null.format" = [90mnull[0m[0m
                } [90m-> null[0m[0m
              [31m-[0m[0m serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe" [90m-> null[0m[0m
            }
        }
    }

[1m  # module.lake.aws_s3_bucket.this["raw"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket" "this" {
      [31m-[0m[0m arn                         = "arn:aws:s3:::eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m bucket                      = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m bucket_domain_name          = "eda262-g02-lake-raw.s3.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m bucket_regional_domain_name = "eda262-g02-lake-raw.s3.us-east-1.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy               = true [90m-> null[0m[0m
      [31m-[0m[0m hosted_zone_id              = "Z3AQBSTGFYJSTF" [90m-> null[0m[0m
      [31m-[0m[0m id                          = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m object_lock_enabled         = false [90m-> null[0m[0m
      [31m-[0m[0m region                      = "us-east-1" [90m-> null[0m[0m
      [31m-[0m[0m request_payer               = "BucketOwner" [90m-> null[0m[0m
      [31m-[0m[0m tags                        = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                    = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m grant {
          [31m-[0m[0m id          = "8022b3bfe1e45d090335847dc77b594076fc7367a05e12aaab58998de2bef47e" [90m-> null[0m[0m
          [31m-[0m[0m permissions = [
              [31m-[0m[0m "FULL_CONTROL",
            ] [90m-> null[0m[0m
          [31m-[0m[0m type        = "CanonicalUser" [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }

      [31m-[0m[0m server_side_encryption_configuration {
          [31m-[0m[0m rule {
              [31m-[0m[0m bucket_key_enabled = false [90m-> null[0m[0m

              [31m-[0m[0m apply_server_side_encryption_by_default {
                  [31m-[0m[0m sse_algorithm     = "AES256" [90m-> null[0m[0m
                    [90m# (1 unchanged attribute hidden)[0m[0m
                }
            }
        }

      [31m-[0m[0m versioning {
          [31m-[0m[0m enabled    = false [90m-> null[0m[0m
          [31m-[0m[0m mfa_delete = false [90m-> null[0m[0m
        }
    }

[1m  # module.lake.aws_s3_bucket.this["resultados"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket" "this" {
      [31m-[0m[0m arn                         = "arn:aws:s3:::eda262-g02-athena-results" [90m-> null[0m[0m
      [31m-[0m[0m bucket                      = "eda262-g02-athena-results" [90m-> null[0m[0m
      [31m-[0m[0m bucket_domain_name          = "eda262-g02-athena-results.s3.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m bucket_regional_domain_name = "eda262-g02-athena-results.s3.us-east-1.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy               = true [90m-> null[0m[0m
      [31m-[0m[0m hosted_zone_id              = "Z3AQBSTGFYJSTF" [90m-> null[0m[0m
      [31m-[0m[0m id                          = "eda262-g02-athena-results" [90m-> null[0m[0m
      [31m-[0m[0m object_lock_enabled         = false [90m-> null[0m[0m
      [31m-[0m[0m region                      = "us-east-1" [90m-> null[0m[0m
      [31m-[0m[0m request_payer               = "BucketOwner" [90m-> null[0m[0m
      [31m-[0m[0m tags                        = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                    = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m grant {
          [31m-[0m[0m id          = "8022b3bfe1e45d090335847dc77b594076fc7367a05e12aaab58998de2bef47e" [90m-> null[0m[0m
          [31m-[0m[0m permissions = [
              [31m-[0m[0m "FULL_CONTROL",
            ] [90m-> null[0m[0m
          [31m-[0m[0m type        = "CanonicalUser" [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }

      [31m-[0m[0m server_side_encryption_configuration {
          [31m-[0m[0m rule {
              [31m-[0m[0m bucket_key_enabled = false [90m-> null[0m[0m

              [31m-[0m[0m apply_server_side_encryption_by_default {
                  [31m-[0m[0m sse_algorithm     = "AES256" [90m-> null[0m[0m
                    [90m# (1 unchanged attribute hidden)[0m[0m
                }
            }
        }

      [31m-[0m[0m versioning {
          [31m-[0m[0m enabled    = false [90m-> null[0m[0m
          [31m-[0m[0m mfa_delete = false [90m-> null[0m[0m
        }
    }

[1m  # module.lake.aws_s3_bucket.this["trusted"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket" "this" {
      [31m-[0m[0m arn                         = "arn:aws:s3:::eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m bucket                      = "eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m bucket_domain_name          = "eda262-g02-lake-trusted.s3.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m bucket_regional_domain_name = "eda262-g02-lake-trusted.s3.us-east-1.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy               = true [90m-> null[0m[0m
      [31m-[0m[0m hosted_zone_id              = "Z3AQBSTGFYJSTF" [90m-> null[0m[0m
      [31m-[0m[0m id                          = "eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m object_lock_enabled         = false [90m-> null[0m[0m
      [31m-[0m[0m region                      = "us-east-1" [90m-> null[0m[0m
      [31m-[0m[0m request_payer               = "BucketOwner" [90m-> null[0m[0m
      [31m-[0m[0m tags                        = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                    = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m grant {
          [31m-[0m[0m id          = "8022b3bfe1e45d090335847dc77b594076fc7367a05e12aaab58998de2bef47e" [90m-> null[0m[0m
          [31m-[0m[0m permissions = [
              [31m-[0m[0m "FULL_CONTROL",
            ] [90m-> null[0m[0m
          [31m-[0m[0m type        = "CanonicalUser" [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }

      [31m-[0m[0m server_side_encryption_configuration {
          [31m-[0m[0m rule {
              [31m-[0m[0m bucket_key_enabled = false [90m-> null[0m[0m

              [31m-[0m[0m apply_server_side_encryption_by_default {
                  [31m-[0m[0m sse_algorithm     = "AES256" [90m-> null[0m[0m
                    [90m# (1 unchanged attribute hidden)[0m[0m
                }
            }
        }

      [31m-[0m[0m versioning {
          [31m-[0m[0m enabled    = false [90m-> null[0m[0m
          [31m-[0m[0m mfa_delete = false [90m-> null[0m[0m
        }
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["raw"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [31m-[0m[0m block_public_acls       = true [90m-> null[0m[0m
      [31m-[0m[0m block_public_policy     = true [90m-> null[0m[0m
      [31m-[0m[0m bucket                  = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m id                      = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m ignore_public_acls      = true [90m-> null[0m[0m
      [31m-[0m[0m restrict_public_buckets = true [90m-> null[0m[0m
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["resultados"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [31m-[0m[0m block_public_acls       = true [90m-> null[0m[0m
      [31m-[0m[0m block_public_policy     = true [90m-> null[0m[0m
      [31m-[0m[0m bucket                  = "eda262-g02-athena-results" [90m-> null[0m[0m
      [31m-[0m[0m id                      = "eda262-g02-athena-results" [90m-> null[0m[0m
      [31m-[0m[0m ignore_public_acls      = true [90m-> null[0m[0m
      [31m-[0m[0m restrict_public_buckets = true [90m-> null[0m[0m
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["trusted"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [31m-[0m[0m block_public_acls       = true [90m-> null[0m[0m
      [31m-[0m[0m block_public_policy     = true [90m-> null[0m[0m
      [31m-[0m[0m bucket                  = "eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m id                      = "eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m ignore_public_acls      = true [90m-> null[0m[0m
      [31m-[0m[0m restrict_public_buckets = true [90m-> null[0m[0m
    }

[1m  # module.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_object" "raw" {
      [31m-[0m[0m arn                           = "arn:aws:s3:::eda262-g02-lake-raw/olist/customers/olist_customers_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m bucket                        = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m bucket_key_enabled            = false [90m-> null[0m[0m
      [31m-[0m[0m content_type                  = "text/csv" [90m-> null[0m[0m
      [31m-[0m[0m etag                          = "61d276d8281c0bdcb834466103b42590-2" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy                 = false [90m-> null[0m[0m
      [31m-[0m[0m id                            = "olist/customers/olist_customers_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m key                           = "olist/customers/olist_customers_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m metadata                      = {} [90m-> null[0m[0m
      [31m-[0m[0m server_side_encryption        = "AES256" [90m-> null[0m[0m
      [31m-[0m[0m source                        = "./dados/raw/olist_customers_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m source_hash                   = "8a2c4244856aab4bde3b8ed81f8ca251" [90m-> null[0m[0m
      [31m-[0m[0m storage_class                 = "STANDARD" [90m-> null[0m[0m
      [31m-[0m[0m tags                          = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                      = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (14 unchanged attributes hidden)[0m[0m
    }

[1m  # module.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"][0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_object" "raw" {
      [31m-[0m[0m arn                           = "arn:aws:s3:::eda262-g02-lake-raw/olist/orders/olist_orders_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m bucket                        = "eda262-g02-lake-raw" [90m-> null[0m[0m
      [31m-[0m[0m bucket_key_enabled            = false [90m-> null[0m[0m
      [31m-[0m[0m content_type                  = "text/csv" [90m-> null[0m[0m
      [31m-[0m[0m etag                          = "470aaf9311051e4ee9e975de76d2add2-4" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy                 = false [90m-> null[0m[0m
      [31m-[0m[0m id                            = "olist/orders/olist_orders_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m key                           = "olist/orders/olist_orders_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m metadata                      = {} [90m-> null[0m[0m
      [31m-[0m[0m server_side_encryption        = "AES256" [90m-> null[0m[0m
      [31m-[0m[0m source                        = "./dados/raw/olist_orders_dataset.csv" [90m-> null[0m[0m
      [31m-[0m[0m source_hash                   = "8bd60e55c1ca229d9f70b62f3e72f22c" [90m-> null[0m[0m
      [31m-[0m[0m storage_class                 = "STANDARD" [90m-> null[0m[0m
      [31m-[0m[0m tags                          = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                      = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (14 unchanged attributes hidden)[0m[0m
    }

[1m  # module.lake.aws_s3_object.trusted[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_object" "trusted" {
      [31m-[0m[0m arn                           = "arn:aws:s3:::eda262-g02-lake-trusted/pedidos_entrega/pedidos_entrega.csv" [90m-> null[0m[0m
      [31m-[0m[0m bucket                        = "eda262-g02-lake-trusted" [90m-> null[0m[0m
      [31m-[0m[0m bucket_key_enabled            = false [90m-> null[0m[0m
      [31m-[0m[0m content_type                  = "text/csv" [90m-> null[0m[0m
      [31m-[0m[0m etag                          = "49876b786f8a34dce655fcbb6da46081-3" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy                 = false [90m-> null[0m[0m
      [31m-[0m[0m id                            = "pedidos_entrega/pedidos_entrega.csv" [90m-> null[0m[0m
      [31m-[0m[0m key                           = "pedidos_entrega/pedidos_entrega.csv" [90m-> null[0m[0m
      [31m-[0m[0m metadata                      = {} [90m-> null[0m[0m
      [31m-[0m[0m server_side_encryption        = "AES256" [90m-> null[0m[0m
      [31m-[0m[0m source                        = "./dados/trusted/pedidos_entrega.csv" [90m-> null[0m[0m
      [31m-[0m[0m source_hash                   = "0b092ec644759fadc50f3ec3d00891ed" [90m-> null[0m[0m
      [31m-[0m[0m storage_class                 = "STANDARD" [90m-> null[0m[0m
      [31m-[0m[0m tags                          = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                      = {
          [31m-[0m[0m "grupo"     = "g02"
          [31m-[0m[0m "projeto"   = "engenharia-de-dados"
          [31m-[0m[0m "turma"     = "eda262"
          [31m-[0m[0m "workspace" = "av1"
        } [90m-> null[0m[0m
        [90m# (14 unchanged attributes hidden)[0m[0m
    }

[1mPlan:[0m [0m0 to add, 0 to change, 13 to destroy.

Changes to Outputs:
  [31m-[0m[0m banco_glue        = "eda262_g02_entregas_ecommerce" [90m-> null[0m[0m
  [31m-[0m[0m bucket_raw        = "eda262-g02-lake-raw" [90m-> null[0m[0m
  [31m-[0m[0m bucket_resultados = "eda262-g02-athena-results" [90m-> null[0m[0m
  [31m-[0m[0m bucket_trusted    = "eda262-g02-lake-trusted" [90m-> null[0m[0m
  [31m-[0m[0m consulta_salva_id = "108f917a-dfa2-40da-95c8-2ab8581b32a3" [90m-> null[0m[0m
  [31m-[0m[0m local_trusted     = "s3://eda262-g02-lake-trusted/pedidos_entrega/" [90m-> null[0m[0m
  [31m-[0m[0m regiao            = "us-east-1" [90m-> null[0m[0m
  [31m-[0m[0m tabela_glue       = "pedidos_entrega" [90m-> null[0m[0m
  [31m-[0m[0m workgroup         = "eda262-g02-wg" [90m-> null[0m[0m
[0m[1m
Do you really want to destroy all resources in workspace "av1"?[0m
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  [1mEnter a value:[0m [0m
[0m[1mmodule.lake.aws_athena_named_query.pergunta: Destroying... [id=108f917a-dfa2-40da-95c8-2ab8581b32a3][0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["resultados"]: Destroying... [id=eda262-g02-athena-results][0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["raw"]: Destroying... [id=eda262-g02-lake-raw][0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["trusted"]: Destroying... [id=eda262-g02-lake-trusted][0m[0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"]: Destroying... [id=olist/customers/olist_customers_dataset.csv][0m[0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"]: Destroying... [id=olist/orders/olist_orders_dataset.csv][0m[0m
[0m[1mmodule.lake.aws_glue_catalog_table.pedidos_entrega: Destroying... [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce:pedidos_entrega][0m[0m
[0m[1mmodule.lake.aws_athena_named_query.pergunta: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_athena_workgroup.this: Destroying... [id=eda262-g02-wg][0m[0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["trusted"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_athena_workgroup.this: Destruction complete after 0s[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["raw"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["resultados"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_glue_catalog_table.pedidos_entrega: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_object.trusted: Destroying... [id=pedidos_entrega/pedidos_entrega.csv][0m[0m
[0m[1mmodule.lake.aws_glue_catalog_database.this: Destroying... [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce][0m[0m
[0m[1mmodule.lake.aws_s3_object.trusted: Destruction complete after 0s[0m
[0m[1mmodule.lake.aws_s3_bucket.this["raw"]: Destroying... [id=eda262-g02-lake-raw][0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["trusted"]: Destroying... [id=eda262-g02-lake-trusted][0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["resultados"]: Destroying... [id=eda262-g02-athena-results][0m[0m
[0m[1mmodule.lake.aws_glue_catalog_database.this: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_bucket.this["trusted"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_bucket.this["raw"]: Destruction complete after 1s[0m
[0m[1mmodule.lake.aws_s3_bucket.this["resultados"]: Destruction complete after 2s[0m
[0m[1m[32m
Destroy complete! Resources: 13 destroyed.[0m
# ---- fim (UTC): 2026-10-03T00:52:03Z | codigo de saida: 0
