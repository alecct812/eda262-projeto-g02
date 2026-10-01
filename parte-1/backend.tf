# Backend remoto criado por parte-1/bootstrap. Valores fixos: não há segredo nem ID de conta.
# Workspace não default grava em <workspace_key_prefix>/<workspace>/<key>,
# ou seja, eda262-g02/av1/parte-1/terraform.tfstate.
# dynamodb_table está deprecado no Terraform atual (aviso na saída), mas o guia exige DynamoDB.
terraform {
  backend "s3" {
    bucket               = "eda262-g02-tfstate"
    key                  = "parte-1/terraform.tfstate"
    region               = "us-east-1"
    dynamodb_table       = "eda262-g02-tflock"
    encrypt              = true
    workspace_key_prefix = "eda262-g02"
  }
}
