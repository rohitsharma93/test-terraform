# ==============================================================================
# Terraform Remote State Backend Configuration (S3 + DynamoDB Locking)
# ==============================================================================
# To activate remote state management:
# 1. Ensure the S3 bucket and DynamoDB lock table exist in your AWS account.
# 2. Uncomment the backend block below.
# 3. Run: terraform init -migrate-state
#
# terraform {
#   backend "s3" {
#     bucket         = "rohit-demo-terraform-state-us-east-1"
#     key            = "infrastructure/demo/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-locks"
#     encrypt        = true
#   }
# }
