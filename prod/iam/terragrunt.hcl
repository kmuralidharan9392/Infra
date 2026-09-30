include "root" {
  path = find_in_parent_folders()
}

# 🟢 Tells Terragrunt where to find the single central source of truth for the iam
terraform {
  source = "../../../modules/iam"
}

# 🟢 Automatically read values from the surrounding /prod/env.hcl file
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# 🟢 Map those local configurations down to the module's input variables
inputs = {
  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region
}