# Public-safe remote state example only.
# Real backend bucket and lock-table names are user-owned and must not be committed.
# Validation uses backend-disabled initialisation: terraform init -backend=false.
terraform {
  backend "s3" {
    bucket         = "example-prod-terraform-state-bucket-do-not-use"
    key            = "platform-infra-lab/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "example-prod-terraform-locks-do-not-use"
    encrypt        = true
  }
}
