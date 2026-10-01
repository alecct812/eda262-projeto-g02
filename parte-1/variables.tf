variable "regiao" {
  description = "Região AWS da Parte 1."
  type        = string
  default     = "us-east-1"
}

variable "grupo" {
  description = "Identificador do grupo no padrão gNN."
  type        = string
  default     = "g02"

  validation {
    condition     = can(regex("^g[0-9]{2}$", var.grupo))
    error_message = "Use o padrão gNN, por exemplo g02."
  }
}

variable "teto_bytes_consulta" {
  description = "Limite de bytes varridos por consulta no workgroup. Justificativa medida no DECISOES.md."
  type        = number
  default     = 52428800 # 50 MiB
}
