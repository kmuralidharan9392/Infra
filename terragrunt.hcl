# Generate AWS Provider configuration for all modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-south-1"
}
EOF
}

# Configure global remote state management via S3 and DynamoDB
remote_state {
  backend = "s3"

   # 🟢 MOVE THE CONTROLS HERE (OUTSIDE THE CONFIG BLOCK)
  skip_bucket_ssesh_check   = true
  skip_bucket_root_access   = true
  skip_bucket_enforced_tls  = true
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "preva-infra-tfstate-prod-ap-south-1"
    # path_relative_to_include() ensures states are separated like: infra/cognito/terraform.tfstate
    key            = "infra/${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "preva-infra-tflocks-prod-ap-south-1"
  }
}
