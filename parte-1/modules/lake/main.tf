locals {
  buckets = {
    raw        = "${var.prefixo}-lake-raw"
    trusted    = "${var.prefixo}-lake-trusted"
    resultados = "${var.prefixo}-athena-results"
  }
  pasta_trusted = "pedidos_entrega"

  # Schema declarado no IaC (sem Crawler). Ordem idêntica a COLUNAS em preparo/prepara_trusted.py.
  colunas_trusted = [
    { nome = "id_pedido", tipo = "string", comentario = "order_id da Olist; chave da tabela (grao: um pedido)" },
    { nome = "uf_cliente", tipo = "string", comentario = "UF de destino (customer_state via customer_id)" },
    { nome = "status_pedido", tipo = "string", comentario = "order_status original" },
    { nome = "data_hora_compra", tipo = "timestamp", comentario = "order_purchase_timestamp" },
    { nome = "data_prevista_entrega", tipo = "date", comentario = "order_estimated_delivery_date (sempre 00:00:00 na origem)" },
    { nome = "data_hora_entrega", tipo = "timestamp", comentario = "order_delivered_customer_date; nulo se nao entregue" },
    { nome = "elegivel", tipo = "boolean", comentario = "entra no indicador: delivered com data de entrega" },
    { nome = "atrasado", tipo = "boolean", comentario = "dia da entrega posterior ao dia previsto; nulo se nao elegivel" },
    { nome = "dias_atraso", tipo = "int", comentario = "dias entre entrega e previsao (negativo = antecipado)" },
    { nome = "motivo_exclusao", tipo = "string", comentario = "status_nao_entregue ou entregue_sem_data; nulo se elegivel" },
  ]
}

resource "aws_s3_bucket" "this" {
  for_each = local.buckets

  bucket        = each.value
  force_destroy = true # destroy remove os dados junto: nenhum bucket órfão
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Carga dos dados como recurso Terraform: o destroy apaga os objetos sem passo manual.
resource "aws_s3_object" "raw" {
  for_each = var.arquivos_raw

  bucket       = aws_s3_bucket.this["raw"].id
  key          = each.key
  source       = each.value
  source_hash  = filemd5(each.value)
  content_type = "text/csv"
}

resource "aws_s3_object" "trusted" {
  bucket       = aws_s3_bucket.this["trusted"].id
  key          = "${local.pasta_trusted}/pedidos_entrega.csv"
  source       = var.arquivo_trusted
  source_hash  = filemd5(var.arquivo_trusted)
  content_type = "text/csv"
}

resource "aws_glue_catalog_database" "this" {
  name        = var.banco_glue
  description = "Data Lake da Parte 1: atrasos de entrega de e-commerce (Olist)"
}

resource "aws_glue_catalog_table" "pedidos_entrega" {
  name          = "pedidos_entrega"
  database_name = aws_glue_catalog_database.this.name
  description   = "Trusted: uma linha por pedido (grao), chave id_pedido"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    classification           = "csv"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.this["trusted"].bucket}/${local.pasta_trusted}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv-sem-aspas"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"               = ","
        "serialization.format"      = ","
        "serialization.null.format" = ""
      }
    }

    dynamic "columns" {
      for_each = local.colunas_trusted

      content {
        name    = columns.value.nome
        type    = columns.value.tipo
        comment = columns.value.comentario
      }
    }
  }

  depends_on = [aws_s3_object.trusted]
}

resource "aws_athena_workgroup" "this" {
  name          = "${var.prefixo}-wg"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    bytes_scanned_cutoff_per_query     = var.teto_bytes_consulta

    result_configuration {
      output_location = "s3://${aws_s3_bucket.this["resultados"].bucket}/resultados/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "pergunta" {
  name        = "${var.prefixo}-pergunta-atrasos-uf"
  description = "Pergunta da AV1: atrasos de entrega por UF de destino (2017-01 a 2018-08)"
  workgroup   = aws_athena_workgroup.this.id
  database    = aws_glue_catalog_database.this.name
  query       = var.sql_pergunta
}
