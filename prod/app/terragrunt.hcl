include "root" {
  path = find_in_parent_folders()
}

# 🟢 Tells Terragrunt where to find the single central source of truth for the EC2 TF code
terraform {
  source = "../../modules/app"
}

# 🟢 Automatically read values from the surrounding /prod/env.hcl file
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# 1. Pull details from your Cognito workspace state file
dependency "cognito" {
  # 🟢 UPDATED: Stays as "../cognito" because they are still neighbors inside the /prod folder!
  config_path = "../cognito"

  # 🟢 Added mock outputs for the plan phase
  mock_outputs = {
    cognito_client_id = "mock-client-id"
    cognito_user_pool_id  = "mock-user-pool-id"
    cognito_client_secret = "mock-client-secret-string-12345"
  }
  # 🟢 Fixed: Changed to allowed commands configuration
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]

  # 🟢 If this is true, Terragrunt won't even look at the S3 state file!
  # It will strictly use the mock_outputs block instead.
  skip_outputs = get_env("INITIAL_BOOTSTRAP", "false") == "true"
}

# 2. Pull details from your custom VPC workspace state file
dependency "vpc" {
  # 🟢 UPDATED: Stays as "../vpc" because it is also a neighbor inside the /prod folder!
  config_path = "../vpc"

    # 🟢 Added mock outputs for the plan phase
  mock_outputs = {
    vpc_id           = "vpc-12345678"
    public_subnet_id = "subnet-12345678"
  }
  # 🟢 Fixed: Changed to allowed commands configuration
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]

  # 🟢 If this is true, Terragrunt won't even look at the S3 state file!
  # It will strictly use the mock_outputs block instead.
  skip_outputs = get_env("INITIAL_BOOTSTRAP", "false") == "true"
}

# 3. Pull details from your custom IAM workspace state file
dependency "iam" {
  config_path = "../iam"

    # 🟢 Added mock outputs for the plan phase
  mock_outputs = {
    instance_profile_name = "mock-instance-profile-name"
  }
  # 🟢 Fixed: Changed to allowed commands configuration
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]

  # 🟢 If this is true, Terragrunt won't even look at the S3 state file!
  # It will strictly use the mock_outputs block instead.
  skip_outputs = get_env("INITIAL_BOOTSTRAP", "false") == "true"
}

# 🟢 Map those local configurations down to the module's input variables
inputs = {

  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region

  vpc_id                = dependency.vpc.outputs.vpc_id
  public_subnet_id      = dependency.vpc.outputs.public_subnet_id
  instance_profile_name = dependency.iam.outputs.instance_profile_name

  # 🟢 Pass all three Cognito values down to the app server module
  cognito_client_id     = dependency.cognito.outputs.cognito_client_id
  cognito_user_pool_id  = dependency.cognito.outputs.cognito_user_pool_id
  cognito_client_secret = dependency.cognito.outputs.cognito_client_secret
}
