# objetivo: README passo 4 / Guia 4.1: provisionar o Data Lake (buckets, objetos, Glue, workgroup, consulta salva) no workspace av1
# diretorio: eda262-g02-revisao
# comando: printf "yes\n" | terraform -chdir=parte-1 apply
# inicio (UTC): 2026-10-03T00:45:04Z
# ---- saida ----
[33m╷[0m[0m
[33m│[0m [0m[1m[33mWarning: [0m[0m[1mDeprecated Parameter[0m
[33m│[0m [0m
[33m│[0m [0m[0mThe parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
[33m│[0m [0minstead.
[33m╵[0m[0m
Acquiring state lock. This may take a few moments...
[0m[1mdata.aws_region.atual: Reading...[0m[0m
[0m[1mdata.aws_region.atual: Read complete after 0s [id=us-east-1][0m

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  [32m+[0m create[0m

Terraform will perform the following actions:

[1m  # module.lake.aws_athena_named_query.pergunta[0m will be created
[0m  [32m+[0m[0m resource "aws_athena_named_query" "pergunta" {
      [32m+[0m[0m database    = "eda262_g02_entregas_ecommerce"
      [32m+[0m[0m description = "Pergunta da AV1: atrasos de entrega por UF de destino (2017-01 a 2018-08)"
      [32m+[0m[0m id          = (known after apply)
      [32m+[0m[0m name        = "eda262-g02-pergunta-atrasos-uf"
      [32m+[0m[0m query       = <<-EOT
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
        EOT
      [32m+[0m[0m workgroup   = (known after apply)
    }

[1m  # module.lake.aws_athena_workgroup.this[0m will be created
[0m  [32m+[0m[0m resource "aws_athena_workgroup" "this" {
      [32m+[0m[0m arn           = (known after apply)
      [32m+[0m[0m force_destroy = true
      [32m+[0m[0m id            = (known after apply)
      [32m+[0m[0m name          = "eda262-g02-wg"
      [32m+[0m[0m state         = "ENABLED"
      [32m+[0m[0m tags_all      = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }

      [32m+[0m[0m configuration {
          [32m+[0m[0m bytes_scanned_cutoff_per_query     = 52428800
          [32m+[0m[0m enforce_workgroup_configuration    = true
          [32m+[0m[0m publish_cloudwatch_metrics_enabled = false
          [32m+[0m[0m requester_pays_enabled             = false

          [32m+[0m[0m result_configuration {
              [32m+[0m[0m output_location = "s3://eda262-g02-athena-results/resultados/"

              [32m+[0m[0m encryption_configuration {
                  [32m+[0m[0m encryption_option = "SSE_S3"
                }
            }
        }
    }

[1m  # module.lake.aws_glue_catalog_database.this[0m will be created
[0m  [32m+[0m[0m resource "aws_glue_catalog_database" "this" {
      [32m+[0m[0m arn          = (known after apply)
      [32m+[0m[0m catalog_id   = (known after apply)
      [32m+[0m[0m description  = "Data Lake da Parte 1: atrasos de entrega de e-commerce (Olist)"
      [32m+[0m[0m id           = (known after apply)
      [32m+[0m[0m location_uri = (known after apply)
      [32m+[0m[0m name         = "eda262_g02_entregas_ecommerce"
      [32m+[0m[0m tags_all     = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }

      [32m+[0m[0m create_table_default_permission (known after apply)
    }

[1m  # module.lake.aws_glue_catalog_table.pedidos_entrega[0m will be created
[0m  [32m+[0m[0m resource "aws_glue_catalog_table" "pedidos_entrega" {
      [32m+[0m[0m arn           = (known after apply)
      [32m+[0m[0m catalog_id    = (known after apply)
      [32m+[0m[0m database_name = "eda262_g02_entregas_ecommerce"
      [32m+[0m[0m description   = "Trusted: uma linha por pedido (grao), chave id_pedido"
      [32m+[0m[0m id            = (known after apply)
      [32m+[0m[0m name          = "pedidos_entrega"
      [32m+[0m[0m parameters    = {
          [32m+[0m[0m "EXTERNAL"               = "TRUE"
          [32m+[0m[0m "classification"         = "csv"
          [32m+[0m[0m "skip.header.line.count" = "1"
        }
      [32m+[0m[0m table_type    = "EXTERNAL_TABLE"

      [32m+[0m[0m partition_index (known after apply)

      [32m+[0m[0m storage_descriptor {
          [32m+[0m[0m input_format  = "org.apache.hadoop.mapred.TextInputFormat"
          [32m+[0m[0m location      = "s3://eda262-g02-lake-trusted/pedidos_entrega/"
          [32m+[0m[0m output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "order_id da Olist; chave da tabela (grao: um pedido)"
              [32m+[0m[0m name    = "id_pedido"
              [32m+[0m[0m type    = "string"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "UF de destino (customer_state via customer_id)"
              [32m+[0m[0m name    = "uf_cliente"
              [32m+[0m[0m type    = "string"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "order_status original"
              [32m+[0m[0m name    = "status_pedido"
              [32m+[0m[0m type    = "string"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "order_purchase_timestamp"
              [32m+[0m[0m name    = "data_hora_compra"
              [32m+[0m[0m type    = "timestamp"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "order_estimated_delivery_date (sempre 00:00:00 na origem)"
              [32m+[0m[0m name    = "data_prevista_entrega"
              [32m+[0m[0m type    = "date"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "order_delivered_customer_date; nulo se nao entregue"
              [32m+[0m[0m name    = "data_hora_entrega"
              [32m+[0m[0m type    = "timestamp"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "entra no indicador: delivered com data de entrega"
              [32m+[0m[0m name    = "elegivel"
              [32m+[0m[0m type    = "boolean"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "dia da entrega posterior ao dia previsto; nulo se nao elegivel"
              [32m+[0m[0m name    = "atrasado"
              [32m+[0m[0m type    = "boolean"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "dias entre entrega e previsao (negativo = antecipado)"
              [32m+[0m[0m name    = "dias_atraso"
              [32m+[0m[0m type    = "int"
            }
          [32m+[0m[0m columns {
              [32m+[0m[0m comment = "status_nao_entregue ou entregue_sem_data; nulo se elegivel"
              [32m+[0m[0m name    = "motivo_exclusao"
              [32m+[0m[0m type    = "string"
            }

          [32m+[0m[0m ser_de_info {
              [32m+[0m[0m name                  = "csv-sem-aspas"
              [32m+[0m[0m parameters            = {
                  [32m+[0m[0m "field.delim"               = ","
                  [32m+[0m[0m "serialization.format"      = ","
                  [32m+[0m[0m "serialization.null.format" = [90mnull[0m[0m
                }
              [32m+[0m[0m serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
            }
        }
    }

[1m  # module.lake.aws_s3_bucket.this["raw"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket" "this" {
      [32m+[0m[0m acceleration_status         = (known after apply)
      [32m+[0m[0m acl                         = (known after apply)
      [32m+[0m[0m arn                         = (known after apply)
      [32m+[0m[0m bucket                      = "eda262-g02-lake-raw"
      [32m+[0m[0m bucket_domain_name          = (known after apply)
      [32m+[0m[0m bucket_prefix               = (known after apply)
      [32m+[0m[0m bucket_regional_domain_name = (known after apply)
      [32m+[0m[0m force_destroy               = true
      [32m+[0m[0m hosted_zone_id              = (known after apply)
      [32m+[0m[0m id                          = (known after apply)
      [32m+[0m[0m object_lock_enabled         = (known after apply)
      [32m+[0m[0m policy                      = (known after apply)
      [32m+[0m[0m region                      = (known after apply)
      [32m+[0m[0m request_payer               = (known after apply)
      [32m+[0m[0m tags_all                    = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m website_domain              = (known after apply)
      [32m+[0m[0m website_endpoint            = (known after apply)

      [32m+[0m[0m cors_rule (known after apply)

      [32m+[0m[0m grant (known after apply)

      [32m+[0m[0m lifecycle_rule (known after apply)

      [32m+[0m[0m logging (known after apply)

      [32m+[0m[0m object_lock_configuration (known after apply)

      [32m+[0m[0m replication_configuration (known after apply)

      [32m+[0m[0m server_side_encryption_configuration (known after apply)

      [32m+[0m[0m versioning (known after apply)

      [32m+[0m[0m website (known after apply)
    }

[1m  # module.lake.aws_s3_bucket.this["resultados"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket" "this" {
      [32m+[0m[0m acceleration_status         = (known after apply)
      [32m+[0m[0m acl                         = (known after apply)
      [32m+[0m[0m arn                         = (known after apply)
      [32m+[0m[0m bucket                      = "eda262-g02-athena-results"
      [32m+[0m[0m bucket_domain_name          = (known after apply)
      [32m+[0m[0m bucket_prefix               = (known after apply)
      [32m+[0m[0m bucket_regional_domain_name = (known after apply)
      [32m+[0m[0m force_destroy               = true
      [32m+[0m[0m hosted_zone_id              = (known after apply)
      [32m+[0m[0m id                          = (known after apply)
      [32m+[0m[0m object_lock_enabled         = (known after apply)
      [32m+[0m[0m policy                      = (known after apply)
      [32m+[0m[0m region                      = (known after apply)
      [32m+[0m[0m request_payer               = (known after apply)
      [32m+[0m[0m tags_all                    = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m website_domain              = (known after apply)
      [32m+[0m[0m website_endpoint            = (known after apply)

      [32m+[0m[0m cors_rule (known after apply)

      [32m+[0m[0m grant (known after apply)

      [32m+[0m[0m lifecycle_rule (known after apply)

      [32m+[0m[0m logging (known after apply)

      [32m+[0m[0m object_lock_configuration (known after apply)

      [32m+[0m[0m replication_configuration (known after apply)

      [32m+[0m[0m server_side_encryption_configuration (known after apply)

      [32m+[0m[0m versioning (known after apply)

      [32m+[0m[0m website (known after apply)
    }

[1m  # module.lake.aws_s3_bucket.this["trusted"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket" "this" {
      [32m+[0m[0m acceleration_status         = (known after apply)
      [32m+[0m[0m acl                         = (known after apply)
      [32m+[0m[0m arn                         = (known after apply)
      [32m+[0m[0m bucket                      = "eda262-g02-lake-trusted"
      [32m+[0m[0m bucket_domain_name          = (known after apply)
      [32m+[0m[0m bucket_prefix               = (known after apply)
      [32m+[0m[0m bucket_regional_domain_name = (known after apply)
      [32m+[0m[0m force_destroy               = true
      [32m+[0m[0m hosted_zone_id              = (known after apply)
      [32m+[0m[0m id                          = (known after apply)
      [32m+[0m[0m object_lock_enabled         = (known after apply)
      [32m+[0m[0m policy                      = (known after apply)
      [32m+[0m[0m region                      = (known after apply)
      [32m+[0m[0m request_payer               = (known after apply)
      [32m+[0m[0m tags_all                    = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m website_domain              = (known after apply)
      [32m+[0m[0m website_endpoint            = (known after apply)

      [32m+[0m[0m cors_rule (known after apply)

      [32m+[0m[0m grant (known after apply)

      [32m+[0m[0m lifecycle_rule (known after apply)

      [32m+[0m[0m logging (known after apply)

      [32m+[0m[0m object_lock_configuration (known after apply)

      [32m+[0m[0m replication_configuration (known after apply)

      [32m+[0m[0m server_side_encryption_configuration (known after apply)

      [32m+[0m[0m versioning (known after apply)

      [32m+[0m[0m website (known after apply)
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["raw"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [32m+[0m[0m block_public_acls       = true
      [32m+[0m[0m block_public_policy     = true
      [32m+[0m[0m bucket                  = (known after apply)
      [32m+[0m[0m id                      = (known after apply)
      [32m+[0m[0m ignore_public_acls      = true
      [32m+[0m[0m restrict_public_buckets = true
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["resultados"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [32m+[0m[0m block_public_acls       = true
      [32m+[0m[0m block_public_policy     = true
      [32m+[0m[0m bucket                  = (known after apply)
      [32m+[0m[0m id                      = (known after apply)
      [32m+[0m[0m ignore_public_acls      = true
      [32m+[0m[0m restrict_public_buckets = true
    }

[1m  # module.lake.aws_s3_bucket_public_access_block.this["trusted"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_public_access_block" "this" {
      [32m+[0m[0m block_public_acls       = true
      [32m+[0m[0m block_public_policy     = true
      [32m+[0m[0m bucket                  = (known after apply)
      [32m+[0m[0m id                      = (known after apply)
      [32m+[0m[0m ignore_public_acls      = true
      [32m+[0m[0m restrict_public_buckets = true
    }

[1m  # module.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_object" "raw" {
      [32m+[0m[0m acl                    = (known after apply)
      [32m+[0m[0m arn                    = (known after apply)
      [32m+[0m[0m bucket                 = (known after apply)
      [32m+[0m[0m bucket_key_enabled     = (known after apply)
      [32m+[0m[0m checksum_crc32         = (known after apply)
      [32m+[0m[0m checksum_crc32c        = (known after apply)
      [32m+[0m[0m checksum_crc64nvme     = (known after apply)
      [32m+[0m[0m checksum_sha1          = (known after apply)
      [32m+[0m[0m checksum_sha256        = (known after apply)
      [32m+[0m[0m content_type           = "text/csv"
      [32m+[0m[0m etag                   = (known after apply)
      [32m+[0m[0m force_destroy          = false
      [32m+[0m[0m id                     = (known after apply)
      [32m+[0m[0m key                    = "olist/customers/olist_customers_dataset.csv"
      [32m+[0m[0m kms_key_id             = (known after apply)
      [32m+[0m[0m server_side_encryption = (known after apply)
      [32m+[0m[0m source                 = "./dados/raw/olist_customers_dataset.csv"
      [32m+[0m[0m source_hash            = "8a2c4244856aab4bde3b8ed81f8ca251"
      [32m+[0m[0m storage_class          = (known after apply)
      [32m+[0m[0m tags_all               = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m version_id             = (known after apply)
    }

[1m  # module.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"][0m will be created
[0m  [32m+[0m[0m resource "aws_s3_object" "raw" {
      [32m+[0m[0m acl                    = (known after apply)
      [32m+[0m[0m arn                    = (known after apply)
      [32m+[0m[0m bucket                 = (known after apply)
      [32m+[0m[0m bucket_key_enabled     = (known after apply)
      [32m+[0m[0m checksum_crc32         = (known after apply)
      [32m+[0m[0m checksum_crc32c        = (known after apply)
      [32m+[0m[0m checksum_crc64nvme     = (known after apply)
      [32m+[0m[0m checksum_sha1          = (known after apply)
      [32m+[0m[0m checksum_sha256        = (known after apply)
      [32m+[0m[0m content_type           = "text/csv"
      [32m+[0m[0m etag                   = (known after apply)
      [32m+[0m[0m force_destroy          = false
      [32m+[0m[0m id                     = (known after apply)
      [32m+[0m[0m key                    = "olist/orders/olist_orders_dataset.csv"
      [32m+[0m[0m kms_key_id             = (known after apply)
      [32m+[0m[0m server_side_encryption = (known after apply)
      [32m+[0m[0m source                 = "./dados/raw/olist_orders_dataset.csv"
      [32m+[0m[0m source_hash            = "8bd60e55c1ca229d9f70b62f3e72f22c"
      [32m+[0m[0m storage_class          = (known after apply)
      [32m+[0m[0m tags_all               = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m version_id             = (known after apply)
    }

[1m  # module.lake.aws_s3_object.trusted[0m will be created
[0m  [32m+[0m[0m resource "aws_s3_object" "trusted" {
      [32m+[0m[0m acl                    = (known after apply)
      [32m+[0m[0m arn                    = (known after apply)
      [32m+[0m[0m bucket                 = (known after apply)
      [32m+[0m[0m bucket_key_enabled     = (known after apply)
      [32m+[0m[0m checksum_crc32         = (known after apply)
      [32m+[0m[0m checksum_crc32c        = (known after apply)
      [32m+[0m[0m checksum_crc64nvme     = (known after apply)
      [32m+[0m[0m checksum_sha1          = (known after apply)
      [32m+[0m[0m checksum_sha256        = (known after apply)
      [32m+[0m[0m content_type           = "text/csv"
      [32m+[0m[0m etag                   = (known after apply)
      [32m+[0m[0m force_destroy          = false
      [32m+[0m[0m id                     = (known after apply)
      [32m+[0m[0m key                    = "pedidos_entrega/pedidos_entrega.csv"
      [32m+[0m[0m kms_key_id             = (known after apply)
      [32m+[0m[0m server_side_encryption = (known after apply)
      [32m+[0m[0m source                 = "./dados/trusted/pedidos_entrega.csv"
      [32m+[0m[0m source_hash            = "0b092ec644759fadc50f3ec3d00891ed"
      [32m+[0m[0m storage_class          = (known after apply)
      [32m+[0m[0m tags_all               = {
          [32m+[0m[0m "grupo"     = "g02"
          [32m+[0m[0m "projeto"   = "engenharia-de-dados"
          [32m+[0m[0m "turma"     = "eda262"
          [32m+[0m[0m "workspace" = "av1"
        }
      [32m+[0m[0m version_id             = (known after apply)
    }

[1mPlan:[0m [0m13 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  [32m+[0m[0m banco_glue        = "eda262_g02_entregas_ecommerce"
  [32m+[0m[0m bucket_raw        = "eda262-g02-lake-raw"
  [32m+[0m[0m bucket_resultados = "eda262-g02-athena-results"
  [32m+[0m[0m bucket_trusted    = "eda262-g02-lake-trusted"
  [32m+[0m[0m consulta_salva_id = (known after apply)
  [32m+[0m[0m local_trusted     = "s3://eda262-g02-lake-trusted/pedidos_entrega/"
  [32m+[0m[0m regiao            = "us-east-1"
  [32m+[0m[0m tabela_glue       = "pedidos_entrega"
  [32m+[0m[0m workgroup         = "eda262-g02-wg"
[0m[1m
Do you want to perform these actions in workspace "av1"?[0m
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  [1mEnter a value:[0m [0m
[0m[1mmodule.lake.aws_glue_catalog_database.this: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["trusted"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["raw"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["resultados"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_glue_catalog_database.this: Creation complete after 2s [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce][0m
[0m[1mmodule.lake.aws_s3_bucket.this["raw"]: Creation complete after 4s [id=eda262-g02-lake-raw][0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["trusted"]: Creation complete after 4s [id=eda262-g02-lake-trusted][0m
[0m[1mmodule.lake.aws_s3_object.trusted: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket.this["resultados"]: Creation complete after 5s [id=eda262-g02-athena-results][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["raw"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["resultados"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["trusted"]: Creating...[0m[0m
[0m[1mmodule.lake.aws_athena_workgroup.this: Creating...[0m[0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["resultados"]: Creation complete after 0s [id=eda262-g02-athena-results][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["raw"]: Creation complete after 0s [id=eda262-g02-lake-raw][0m
[0m[1mmodule.lake.aws_s3_bucket_public_access_block.this["trusted"]: Creation complete after 0s [id=eda262-g02-lake-trusted][0m
[0m[1mmodule.lake.aws_athena_workgroup.this: Creation complete after 1s [id=eda262-g02-wg][0m
[0m[1mmodule.lake.aws_athena_named_query.pergunta: Creating...[0m[0m
[0m[1mmodule.lake.aws_athena_named_query.pergunta: Creation complete after 0s [id=108f917a-dfa2-40da-95c8-2ab8581b32a3][0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/customers/olist_customers_dataset.csv"]: Creation complete after 5s [id=olist/customers/olist_customers_dataset.csv][0m
[0m[1mmodule.lake.aws_s3_object.raw["olist/orders/olist_orders_dataset.csv"]: Creation complete after 8s [id=olist/orders/olist_orders_dataset.csv][0m
[0m[1mmodule.lake.aws_s3_object.trusted: Creation complete after 10s [id=pedidos_entrega/pedidos_entrega.csv][0m
[0m[1mmodule.lake.aws_glue_catalog_table.pedidos_entrega: Creating...[0m[0m
[0m[1mmodule.lake.aws_glue_catalog_table.pedidos_entrega: Creation complete after 1s [id=<ACCOUNT_ID>:eda262_g02_entregas_ecommerce:pedidos_entrega][0m
[0m[1m[32m
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.[0m
[0m[1m[32m
Outputs:

[0mbanco_glue = "eda262_g02_entregas_ecommerce"
bucket_raw = "eda262-g02-lake-raw"
bucket_resultados = "eda262-g02-athena-results"
bucket_trusted = "eda262-g02-lake-trusted"
consulta_salva_id = "108f917a-dfa2-40da-95c8-2ab8581b32a3"
local_trusted = "s3://eda262-g02-lake-trusted/pedidos_entrega/"
regiao = "us-east-1"
tabela_glue = "pedidos_entrega"
workgroup = "eda262-g02-wg"
# ---- fim (UTC): 2026-10-03T00:45:31Z | codigo de saida: 0
