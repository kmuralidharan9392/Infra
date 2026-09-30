resource "aws_cognito_user_pool" "user_pool" {
  name = "backend-auth-user-pool"

  # 🟢 1. ALLOW BOTH ALIASES FOR LOGIN DOWN THE LINE
  username_attributes = ["email", "phone_number"]
  
  # Only auto-verify email for now (sends free verification emails)
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # 🟢 2. MANDATORY EMAIL SCHEMA
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true # Must be provided at signup
    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }

  # 🟢 3. OPTIONAL PHONE NUMBER SCHEMA (Ensures future proofing)
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "phone_number"
    required            = false # ◄── CRUCIAL: Keep this false for now!
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
