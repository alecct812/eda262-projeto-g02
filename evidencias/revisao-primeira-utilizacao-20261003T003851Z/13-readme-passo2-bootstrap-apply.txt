# objetivo: README passo 2 / Guia 4.1: criar bucket de state e tabela de trava DynamoDB (confirmacao interativa respondida com yes)
# diretorio: eda262-g02-revisao
# comando: printf "yes\n" | terraform -chdir=parte-1/bootstrap apply
# inicio (UTC): 2026-10-03T00:43:57Z
# ---- saida ----

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  [32m+[0m create[0m

Terraform will perform the following actions:

[1m  # aws_dynamodb_table.trava[0m will be created
[0m  [32m+[0m[0m resource "aws_dynamodb_table" "trava" {
      [32m+[0m[0m arn              = (known after apply)
      [32m+[0m[0m billing_mode     = "PAY_PER_REQUEST"
      [32m+[0m[0m hash_key         = "LockID"
      [32m+[0m[0m id               = (known after apply)
      [32m+[0m[0m name             = "eda262-g02-tflock"
      [32m+[0m[0m read_capacity    = (known after apply)
      [32m+[0m[0m stream_arn       = (known after apply)
      [32m+[0m[0m stream_label     = (known after apply)
      [32m+[0m[0m stream_view_type = (known after apply)
      [32m+[0m[0m tags_all         = {
          [32m+[0m[0m "grupo"   = "g02"
          [32m+[0m[0m "projeto" = "engenharia-de-dados"
          [32m+[0m[0m "turma"   = "eda262"
        }
      [32m+[0m[0m write_capacity   = (known after apply)

      [32m+[0m[0m attribute {
          [32m+[0m[0m name = "LockID"
          [32m+[0m[0m type = "S"
        }

      [32m+[0m[0m point_in_time_recovery (known after apply)

      [32m+[0m[0m server_side_encryption (known after apply)

      [32m+[0m[0m ttl (known after apply)
    }

[1m  # aws_s3_bucket.state[0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket" "state" {
      [32m+[0m[0m acceleration_status         = (known after apply)
      [32m+[0m[0m acl                         = (known after apply)
      [32m+[0m[0m arn                         = (known after apply)
      [32m+[0m[0m bucket                      = "eda262-g02-tfstate"
      [32m+[0m[0m bucket_domain_name          = (known after apply)
      [32m+[0m[0m bucket_prefix               = (known after apply)
      [32m+[0m[0m bucket_regional_domain_name = (known after apply)
      [32m+[0m[0m force_destroy               = true
      [32m+[0m[0m hosted_zone_id              = (known after apply)
      [32m+[0m[0m id                          = (known after apply)
      [32m+[0m[0m object_lock_enabled         = (known after apply)
      [32m+[0m[0m policy                      = (known after apply)
      [32m+[0m[0m region                      = (known after apply)
      [32m+[0m[0m request_payer               = (known after apply)
      [32m+[0m[0m tags_all                    = {
          [32m+[0m[0m "grupo"   = "g02"
          [32m+[0m[0m "projeto" = "engenharia-de-dados"
          [32m+[0m[0m "turma"   = "eda262"
        }
      [32m+[0m[0m website_domain              = (known after apply)
      [32m+[0m[0m website_endpoint            = (known after apply)

      [32m+[0m[0m cors_rule (known after apply)

      [32m+[0m[0m grant (known after apply)

      [32m+[0m[0m lifecycle_rule (known after apply)

      [32m+[0m[0m logging (known after apply)

      [32m+[0m[0m object_lock_configuration (known after apply)

      [32m+[0m[0m replication_configuration (known after apply)

      [32m+[0m[0m server_side_encryption_configuration (known after apply)

      [32m+[0m[0m versioning (known after apply)

      [32m+[0m[0m website (known after apply)
    }

[1m  # aws_s3_bucket_public_access_block.state[0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_public_access_block" "state" {
      [32m+[0m[0m block_public_acls       = true
      [32m+[0m[0m block_public_policy     = true
      [32m+[0m[0m bucket                  = (known after apply)
      [32m+[0m[0m id                      = (known after apply)
      [32m+[0m[0m ignore_public_acls      = true
      [32m+[0m[0m restrict_public_buckets = true
    }

[1m  # aws_s3_bucket_server_side_encryption_configuration.state[0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
      [32m+[0m[0m bucket = (known after apply)
      [32m+[0m[0m id     = (known after apply)

      [32m+[0m[0m rule {
          [32m+[0m[0m apply_server_side_encryption_by_default {
              [32m+[0m[0m sse_algorithm     = "AES256"
                [90m# (1 unchanged attribute hidden)[0m[0m
            }
        }
    }

[1m  # aws_s3_bucket_versioning.state[0m will be created
[0m  [32m+[0m[0m resource "aws_s3_bucket_versioning" "state" {
      [32m+[0m[0m bucket = (known after apply)
      [32m+[0m[0m id     = (known after apply)

      [32m+[0m[0m versioning_configuration {
          [32m+[0m[0m mfa_delete = (known after apply)
          [32m+[0m[0m status     = "Enabled"
        }
    }

[1mPlan:[0m [0m5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  [32m+[0m[0m bucket_state = "eda262-g02-tfstate"
  [32m+[0m[0m tabela_trava = "eda262-g02-tflock"
[0m[1m
Do you want to perform these actions?[0m
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  [1mEnter a value:[0m [0m
[0m[1maws_dynamodb_table.trava: Creating...[0m[0m
[0m[1maws_s3_bucket.state: Creating...[0m[0m
[0m[1maws_s3_bucket.state: Creation complete after 4s [id=eda262-g02-tfstate][0m
[0m[1maws_s3_bucket_server_side_encryption_configuration.state: Creating...[0m[0m
[0m[1maws_s3_bucket_public_access_block.state: Creating...[0m[0m
[0m[1maws_s3_bucket_versioning.state: Creating...[0m[0m
[0m[1maws_s3_bucket_server_side_encryption_configuration.state: Creation complete after 0s [id=eda262-g02-tfstate][0m
[0m[1maws_s3_bucket_public_access_block.state: Creation complete after 1s [id=eda262-g02-tfstate][0m
[0m[1maws_s3_bucket_versioning.state: Creation complete after 2s [id=eda262-g02-tfstate][0m
[0m[1maws_dynamodb_table.trava: Creation complete after 9s [id=eda262-g02-tflock][0m
[0m[1m[32m
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.[0m
[0m[1m[32m
Outputs:

[0mbucket_state = "eda262-g02-tfstate"
tabela_trava = "eda262-g02-tflock"
# ---- fim (UTC): 2026-10-03T00:44:12Z | codigo de saida: 0
