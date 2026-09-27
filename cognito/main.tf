resource "aws_cognito_user_pool" "user_pool" {
  name                = "backend-auth-user-pool"
  username_attributes = ["email"]
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
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "backend-service-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  generate_secret = true 
}

# Outputs exposed to Terragrunt dependencies
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.client.id
}
