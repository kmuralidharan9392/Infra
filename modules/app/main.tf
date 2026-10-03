# 1. Declare environment variables injected by Terragrunt
variable "environment" {
  type        = string
  description = "The deployment environment (e.g., prod, int)"
}

variable "aws_region" {
  type        = string
  description = "The target AWS region (e.g., ap-south-1, us-east-1)"
}

# Dependency injection variables from neighboring workspaces
variable "vpc_id"                { type = string }
variable "public_subnet_id"      { type = string }
variable "instance_profile_name" { type = string }

# 🟢 ADDED: Accepting the complete Cognito bundle
variable "cognito_client_id"     { type = string }
variable "cognito_user_pool_id"  { type = string }
variable "cognito_client_secret" { type = string }

# 2. Fetch the latest official Ubuntu 24.04 LTS AMI in the active region
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's official AWS Owner ID
}

# 3. Create a network security firewall tied to your dynamic VPC
resource "aws_security_group" "app_sg" {
  # 🟢 Dynamic Naming: e.g., "preva-clothing-app-sg-prod-ap-south-1"
  name        = "preva-clothing-app-sg-${var.environment}-${var.aws_region}"
  description = "Security firewall rules for Spring Boot backend"
  vpc_id      = var.vpc_id 

  # Allow public HTTP web traffic to hit port 80
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow administrative SSH access (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Allow all outbound internet traffic (Crucial for calling AWS Cognito API endpoints)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "preva-clothing-app-sg-${var.environment}-${var.aws_region}"
    Environment = var.environment
  }
}

# 4. Provision the EC2 compute server inside your custom architecture
resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro" 
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = var.public_subnet_id 
  iam_instance_profile   = var.instance_profile_name

  # Inject your Cognito settings cleanly as system environment variables on boot
   # 🟢 UPDATED: Port fixed to 8080 and full environment variable context injected!
  user_data = <<-EOF
              #!/bin/bash
              echo "export PORT=8080" >> /etc/profile.d/app_env.sh
              echo "export APP_ENV=${var.environment}" >> /etc/profile.d/app_env.sh
              echo "export AWS_REGION=${var.aws_region}" >> /etc/profile.d/app_env.sh
              echo "export COGNITO_CLIENT_ID=${var.cognito_client_id}" >> /etc/profile.d/app_env.sh
              echo "export COGNITO_USER_POOL_ID=${var.cognito_user_pool_id}" >> /etc/profile.d/app_env.sh
              echo "export COGNITO_CLIENT_SECRET=${var.cognito_client_secret}" >> /etc/profile.d/app_env.sh
              EOF

  tags = {
    # 🟢 Dynamic Naming: e.g., "preva-clothing-backend-prod-ap-south-1"
    Name        = "preva-clothing-backend-${var.environment}-${var.aws_region}"
    Environment = var.environment
    Region      = var.aws_region
  }
}

# Output the public IP so you can easily target it for deployment later
output "server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of your application server"
}
