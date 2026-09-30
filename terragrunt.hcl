# /terragrunt.hcl

locals {
  # Automatically load environment-level variables from the child tree path
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region
}

# 1. Generate AWS Provider configuration dynamically based on the directory's region
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

# 2. Configure global remote state management via S3 and DynamoDB dynamically
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    # Dynamically incorporates region and environment into bucket names
    bucket         = "preva-infra-tfstate-${local.environment}-${local.aws_region}"
    key            = "infra/${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "preva-infra-tflocks-${local.environment}-${local.aws_region}"

    disable_bucket_update = true
  }
}
