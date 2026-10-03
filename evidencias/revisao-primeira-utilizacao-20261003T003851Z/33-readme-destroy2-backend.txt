# objetivo: README Destroy passo 2: destruir o backend por ultimo (guarda o state da etapa anterior)
# diretorio: eda262-g02-revisao
# comando: printf "yes\n" | terraform -chdir=parte-1/bootstrap destroy
# inicio (UTC): 2026-10-03T00:52:03Z
# ---- saida ----
[0m[1maws_s3_bucket.state: Refreshing state... [id=eda262-g02-tfstate][0m
[0m[1maws_dynamodb_table.trava: Refreshing state... [id=eda262-g02-tflock][0m
[0m[1maws_s3_bucket_versioning.state: Refreshing state... [id=eda262-g02-tfstate][0m
[0m[1maws_s3_bucket_public_access_block.state: Refreshing state... [id=eda262-g02-tfstate][0m
[0m[1maws_s3_bucket_server_side_encryption_configuration.state: Refreshing state... [id=eda262-g02-tfstate][0m

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  [31m-[0m destroy[0m

Terraform will perform the following actions:

[1m  # aws_dynamodb_table.trava[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_dynamodb_table" "trava" {
      [31m-[0m[0m arn                         = "arn:aws:dynamodb:us-east-1:<ACCOUNT_ID>:table/eda262-g02-tflock" [90m-> null[0m[0m
      [31m-[0m[0m billing_mode                = "PAY_PER_REQUEST" [90m-> null[0m[0m
      [31m-[0m[0m deletion_protection_enabled = false [90m-> null[0m[0m
      [31m-[0m[0m hash_key                    = "LockID" [90m-> null[0m[0m
      [31m-[0m[0m id                          = "eda262-g02-tflock" [90m-> null[0m[0m
      [31m-[0m[0m name                        = "eda262-g02-tflock" [90m-> null[0m[0m
      [31m-[0m[0m read_capacity               = 0 [90m-> null[0m[0m
      [31m-[0m[0m stream_enabled              = false [90m-> null[0m[0m
      [31m-[0m[0m table_class                 = "STANDARD" [90m-> null[0m[0m
      [31m-[0m[0m tags                        = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                    = {
          [31m-[0m[0m "grupo"   = "g02"
          [31m-[0m[0m "projeto" = "engenharia-de-dados"
          [31m-[0m[0m "turma"   = "eda262"
        } [90m-> null[0m[0m
      [31m-[0m[0m write_capacity              = 0 [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m attribute {
          [31m-[0m[0m name = "LockID" [90m-> null[0m[0m
          [31m-[0m[0m type = "S" [90m-> null[0m[0m
        }

      [31m-[0m[0m point_in_time_recovery {
          [31m-[0m[0m enabled                 = false [90m-> null[0m[0m
          [31m-[0m[0m recovery_period_in_days = 0 [90m-> null[0m[0m
        }

      [31m-[0m[0m ttl {
          [31m-[0m[0m enabled        = false [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }
    }

[1m  # aws_s3_bucket.state[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket" "state" {
      [31m-[0m[0m arn                         = "arn:aws:s3:::eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m bucket                      = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m bucket_domain_name          = "eda262-g02-tfstate.s3.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m bucket_regional_domain_name = "eda262-g02-tfstate.s3.us-east-1.amazonaws.com" [90m-> null[0m[0m
      [31m-[0m[0m force_destroy               = true [90m-> null[0m[0m
      [31m-[0m[0m hosted_zone_id              = "Z3AQBSTGFYJSTF" [90m-> null[0m[0m
      [31m-[0m[0m id                          = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m object_lock_enabled         = false [90m-> null[0m[0m
      [31m-[0m[0m region                      = "us-east-1" [90m-> null[0m[0m
      [31m-[0m[0m request_payer               = "BucketOwner" [90m-> null[0m[0m
      [31m-[0m[0m tags                        = {} [90m-> null[0m[0m
      [31m-[0m[0m tags_all                    = {
          [31m-[0m[0m "grupo"   = "g02"
          [31m-[0m[0m "projeto" = "engenharia-de-dados"
          [31m-[0m[0m "turma"   = "eda262"
        } [90m-> null[0m[0m
        [90m# (3 unchanged attributes hidden)[0m[0m

      [31m-[0m[0m grant {
          [31m-[0m[0m id          = "8022b3bfe1e45d090335847dc77b594076fc7367a05e12aaab58998de2bef47e" [90m-> null[0m[0m
          [31m-[0m[0m permissions = [
              [31m-[0m[0m "FULL_CONTROL",
            ] [90m-> null[0m[0m
          [31m-[0m[0m type        = "CanonicalUser" [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }

      [31m-[0m[0m server_side_encryption_configuration {
          [31m-[0m[0m rule {
              [31m-[0m[0m bucket_key_enabled = false [90m-> null[0m[0m

              [31m-[0m[0m apply_server_side_encryption_by_default {
                  [31m-[0m[0m sse_algorithm     = "AES256" [90m-> null[0m[0m
                    [90m# (1 unchanged attribute hidden)[0m[0m
                }
            }
        }

      [31m-[0m[0m versioning {
          [31m-[0m[0m enabled    = true [90m-> null[0m[0m
          [31m-[0m[0m mfa_delete = false [90m-> null[0m[0m
        }
    }

[1m  # aws_s3_bucket_public_access_block.state[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_public_access_block" "state" {
      [31m-[0m[0m block_public_acls       = true [90m-> null[0m[0m
      [31m-[0m[0m block_public_policy     = true [90m-> null[0m[0m
      [31m-[0m[0m bucket                  = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m id                      = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m ignore_public_acls      = true [90m-> null[0m[0m
      [31m-[0m[0m restrict_public_buckets = true [90m-> null[0m[0m
    }

[1m  # aws_s3_bucket_server_side_encryption_configuration.state[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
      [31m-[0m[0m bucket                = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m id                    = "eda262-g02-tfstate" [90m-> null[0m[0m
        [90m# (1 unchanged attribute hidden)[0m[0m

      [31m-[0m[0m rule {
          [31m-[0m[0m bucket_key_enabled = false [90m-> null[0m[0m

          [31m-[0m[0m apply_server_side_encryption_by_default {
              [31m-[0m[0m sse_algorithm     = "AES256" [90m-> null[0m[0m
                [90m# (1 unchanged attribute hidden)[0m[0m
            }
        }
    }

[1m  # aws_s3_bucket_versioning.state[0m will be [1m[31mdestroyed[0m
[0m  [31m-[0m[0m resource "aws_s3_bucket_versioning" "state" {
      [31m-[0m[0m bucket                = "eda262-g02-tfstate" [90m-> null[0m[0m
      [31m-[0m[0m id                    = "eda262-g02-tfstate" [90m-> null[0m[0m
        [90m# (1 unchanged attribute hidden)[0m[0m

      [31m-[0m[0m versioning_configuration {
          [31m-[0m[0m status     = "Enabled" [90m-> null[0m[0m
            [90m# (1 unchanged attribute hidden)[0m[0m
        }
    }

[1mPlan:[0m [0m0 to add, 0 to change, 5 to destroy.

Changes to Outputs:
  [31m-[0m[0m bucket_state = "eda262-g02-tfstate" [90m-> null[0m[0m
  [31m-[0m[0m tabela_trava = "eda262-g02-tflock" [90m-> null[0m[0m
[0m[1m
Do you really want to destroy all resources?[0m
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  [1mEnter a value:[0m [0m
[0m[1maws_s3_bucket_public_access_block.state: Destroying... [id=eda262-g02-tfstate][0m[0m
[0m[1maws_s3_bucket_server_side_encryption_configuration.state: Destroying... [id=eda262-g02-tfstate][0m[0m
[0m[1maws_s3_bucket_versioning.state: Destroying... [id=eda262-g02-tfstate][0m[0m
[0m[1maws_dynamodb_table.trava: Destroying... [id=eda262-g02-tflock][0m[0m
[0m[1maws_s3_bucket_server_side_encryption_configuration.state: Destruction complete after 1s[0m
[0m[1maws_s3_bucket_public_access_block.state: Destruction complete after 1s[0m
[0m[1maws_s3_bucket_versioning.state: Destruction complete after 2s[0m
[0m[1maws_s3_bucket.state: Destroying... [id=eda262-g02-tfstate][0m[0m
[0m[1maws_s3_bucket.state: Destruction complete after 1s[0m
[0m[1maws_dynamodb_table.trava: Destruction complete after 8s[0m
[0m[1m[32m
Destroy complete! Resources: 5 destroyed.[0m
# ---- fim (UTC): 2026-10-03T00:52:21Z | codigo de saida: 0
