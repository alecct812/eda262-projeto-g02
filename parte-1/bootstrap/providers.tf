provider "aws" {
  region = var.regiao

  default_tags {
    tags = {
      turma   = "eda262"
      grupo   = var.grupo
      projeto = "engenharia-de-dados"
    }
  }
}
