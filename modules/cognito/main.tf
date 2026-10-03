# 1. Define variables to accept inputs from Terragrunt
variable "environment" {
  type        = string
  description = "The deployment environment (e.g., prod, int)"
}

variable "aws_region" {
  type        = string
  description = "The target AWS region (e.g., ap-south-1, us-east-1)"
}

# 2. Dynamic Cognito User Pool Resource Block
resource "aws_cognito_user_pool" "user_pool" {
  # 🟢 Dynamic Naming: output example -> "preva-clothing-user-pool-prod-ap-south-1"
  name = "preva-clothing-user-pool-${var.environment}-${var.aws_region}"

  username_attributes      = ["email", "phone_number"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true 
    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "phone_number"
    required            = false 
  }

  tags = {
    Environment = var.environment
    Region      = var.aws_region
  }
}


# Create the Admin Group
resource "aws_cognito_user_group" "admin_group" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Administrative users with elevated API access"
  precedence   = 1
}

# Create the Customer Group
resource "aws_cognito_user_group" "customer_group" {
  name         = "customer"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Standard retail customer users"
  precedence   = 2
}

# 3. Dynamic Cognito App Client Resource Block
resource "aws_cognito_user_pool_client" "client" {
  # 🟢 Dynamic Naming: output example -> "preva-clothing-client-prod-ap-south-1"
  name         = "preva-clothing-client-${var.environment}-${var.aws_region}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  generate_secret = true 
}

# Outputs remain unchanged, but they map the newly named resources
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

# 🟢 ADDED: We must export the generated client secret!
output "cognito_client_secret" {
  value     = aws_cognito_user_pool_client.client.client_secret
  sensitive = true
}
