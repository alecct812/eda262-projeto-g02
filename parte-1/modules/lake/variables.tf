variable "prefixo" {
  description = "Prefixo dos recursos, no padrão eda262-gNN."
  type        = string
}

variable "banco_glue" {
  description = "Nome do database no Glue Data Catalog (somente minúsculas, números e underscore)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.banco_glue))
    error_message = "Use apenas minúsculas, números e underscore."
  }
}

variable "teto_bytes_consulta" {
  description = "Limite de bytes varridos por consulta no workgroup (mínimo do Athena: 10485760)."
  type        = number

  validation {
    condition     = var.teto_bytes_consulta >= 10485760
    error_message = "O Athena exige pelo menos 10485760 bytes (10 MiB)."
  }
}

variable "arquivos_raw" {
  description = "Mapa chave S3 => caminho local dos arquivos brutos."
  type        = map(string)
}

variable "arquivo_trusted" {
  description = "Caminho local do CSV da trusted pedidos_entrega."
  type        = string
}

variable "sql_pergunta" {
  description = "SQL da pergunta de negócio, registrado como consulta salva no workgroup."
  type        = string
}
