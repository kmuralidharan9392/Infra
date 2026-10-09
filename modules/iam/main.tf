# 1. Declare environment variables injected by Terragrunt
variable "environment" {
  type        = string
  description = "The deployment environment (e.g., prod, int)"
}

variable "aws_region" {
  type        = string
  description = "The target AWS region (e.g., ap-south-1, us-east-1)"
}

# 2. Define the IAM Execution Role for the EC2 Instance
resource "aws_iam_role" "ec2_role" {
  # 🟢 Dynamic Naming: e.g., "preva-clothing-ec2-execution-role-prod-ap-south-1"
  name = "preva-clothing-ec2-execution-role-${var.environment}-${var.aws_region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } # 🟢 Fixed standard service endpoint
    }]
  })

  tags = {
    Environment = var.environment
    Region      = var.aws_region
  }
}

# 3. Attach minimum necessary Cognito permissions to the IAM Role
resource "aws_iam_role_policy" "cognito_access" {
  # 🟢 Dynamic Naming: e.g., "preva-clothing-ec2-cognito-policy-prod-ap-south-1"
  name = "preva-clothing-ec2-cognito-policy-${var.environment}-${var.aws_region}"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "cognito-idp:SignUp",
        "cognito-idp:InitiateAuth",
        "cognito-idp:ConfirmSignUp",
        "cognito-idp:AdminAddUserToGroup"
      ]
      Resource = "*" 
    }]
  })
}

# 4. Wrap the IAM role into an instance profile container
resource "aws_iam_instance_profile" "ec2_profile" {
  # 🟢 Dynamic Naming: e.g., "preva-clothing-ec2-instance-profile-prod-ap-south-1"
  name = "preva-clothing-ec2-instance-profile-${var.environment}-${var.aws_region}"
  role = aws_iam_role.ec2_role.name
}

# --- OUTPUTS (Exposed for the EC2 module to read) ---
output "instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "The name of the IAM instance profile for the EC2 application server"
}
