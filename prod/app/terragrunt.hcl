include "root" {
  path = find_in_parent_folders()
}

# 🟢 Tells Terragrunt where to find the single central source of truth for the EC2 TF code
terraform {
  source = "../../modules/app_server"
}

# 🟢 Automatically read values from the surrounding /prod/env.hcl file
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# 1. Pull details from your Cognito workspace state file
dependency "cognito" {
  # 🟢 UPDATED: Stays as "../cognito" because they are still neighbors inside the /prod folder!
  config_path = "../cognito"
}

# 2. Pull details from your custom VPC workspace state file
dependency "vpc" {
  # 🟢 UPDATED: Stays as "../vpc" because it is also a neighbor inside the /prod folder!
  config_path = "../vpc"
}

# 3. Pull details from your custom IAM workspace state file
dependency "iam" {
  config_path = "../iam"
}

# 🟢 Map those local configurations down to the module's input variables
inputs = {

  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region

  cognito_client_id     = dependency.cognito.outputs.cognito_client_id
  vpc_id                = dependency.vpc.outputs.vpc_id
  public_subnet_id      = dependency.vpc.outputs.public_subnet_id
  instance_profile_name = dependency.iam.outputs.instance_profile_name
}
