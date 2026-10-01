output "regiao" {
  value = data.aws_region.atual.name
}

output "bucket_raw" {
  value = module.lake.bucket_raw
}

output "bucket_trusted" {
  value = module.lake.bucket_trusted
}

output "bucket_resultados" {
  value = module.lake.bucket_resultados
}

output "banco_glue" {
  value = module.lake.banco_glue
}

output "tabela_glue" {
  value = module.lake.tabela_glue
}

output "workgroup" {
  value = module.lake.workgroup
}

output "consulta_salva_id" {
  value = module.lake.consulta_salva_id
}

output "local_trusted" {
  value = module.lake.local_trusted
}
