output "bucket_raw" {
  value = aws_s3_bucket.this["raw"].bucket
}

output "bucket_trusted" {
  value = aws_s3_bucket.this["trusted"].bucket
}

output "bucket_resultados" {
  value = aws_s3_bucket.this["resultados"].bucket
}

output "banco_glue" {
  value = aws_glue_catalog_database.this.name
}

output "tabela_glue" {
  value = aws_glue_catalog_table.pedidos_entrega.name
}

output "workgroup" {
  value = aws_athena_workgroup.this.name
}

output "consulta_salva_id" {
  value = aws_athena_named_query.pergunta.id
}

output "local_trusted" {
  value = aws_glue_catalog_table.pedidos_entrega.storage_descriptor[0].location
}
