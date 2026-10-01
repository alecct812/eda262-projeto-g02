variable "regiao" {
  description = "Região AWS do backend."
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
