# objetivo: README passo 3 / Guia 4.1 (backend S3 + DynamoDB): init da raiz configurando o backend remoto
# diretorio: eda262-g02-revisao
# comando: terraform -chdir=parte-1 init
# inicio (UTC): 2026-10-03T00:44:12Z
# ---- saida ----
[0m[1mInitializing the backend...[0m
[0m[32m
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.[0m

[0m[1mInitializing modules...[0m
- lake in modules\lake

[0m[1mInitializing provider plugins...[0m
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)


[33m╷[0m[0m
[33m│[0m [0m[1m[33mWarning: [0m[0m[1mDeprecated Parameter[0m
[33m│[0m [0m
[33m│[0m [0m[0m  on backend.tf line 10, in terraform:
[33m│[0m [0m  10:     dynamodb_table       = [4m"eda262-g02-tflock"[0m[0m
[33m│[0m [0m
[33m│[0m [0mThe parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
[33m│[0m [0minstead.
[33m╵[0m[0m
[0m[1m[32mTerraform has been successfully initialized![0m[32m[0m
[0m[32m
You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.[0m
# ---- fim (UTC): 2026-10-03T00:44:42Z | codigo de saida: 0
