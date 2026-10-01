# Backend remoto da Parte 1, criado do zero na conta (sem recurso manual).
# State local: este diretório é a única stack sem backend remoto, porque o cria.

locals {
  prefixo = "eda262-${var.grupo}"
}

resource "aws_s3_bucket" "state" {
  bucket = "${local.prefixo}-tfstate"

  # O teardown precisa apagar todas as versões do state para não deixar o bucket órfão.
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "trava" {
  name         = "${local.prefixo}-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
