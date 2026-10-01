# A entrega vive no workspace "av1"; o default fica bloqueado para não misturar states.
data "aws_region" "atual" {
  lifecycle {
    precondition {
      condition     = terraform.workspace != "default"
      error_message = "Workspace default bloqueado. Rode: terraform -chdir=parte-1 workspace select -or-create av1"
    }
  }
}

module "lake" {
  source = "./modules/lake"

  prefixo             = "eda262-${var.grupo}"
  banco_glue          = "eda262_${var.grupo}_entregas_ecommerce"
  teto_bytes_consulta = var.teto_bytes_consulta

  arquivos_raw = {
    "olist/orders/olist_orders_dataset.csv"       = "${path.module}/dados/raw/olist_orders_dataset.csv"
    "olist/customers/olist_customers_dataset.csv" = "${path.module}/dados/raw/olist_customers_dataset.csv"
  }
  arquivo_trusted = "${path.module}/dados/trusted/pedidos_entrega.csv"
  sql_pergunta    = file("${path.module}/consulta/pergunta.sql")
}
