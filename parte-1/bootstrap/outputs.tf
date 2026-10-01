output "bucket_state" {
  description = "Bucket do state remoto da Parte 1."
  value       = aws_s3_bucket.state.bucket
}

output "tabela_trava" {
  description = "Tabela DynamoDB de trava do state."
  value       = aws_dynamodb_table.trava.name
}
