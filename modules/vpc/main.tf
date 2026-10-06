# 1. Declare environment variables injected by Terragrunt
variable "environment" {
  type        = string
  description = "The deployment environment (e.g., prod, int)"
}

variable "aws_region" {
  type        = string
  description = "The target AWS region (e.g., ap-south-1, us-east-1)"
}

# 2. Initialize your custom VPC Network space
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true 
  enable_dns_support   = true

  tags = {
    # 🟢 Dynamic Naming: "preva-clothing-vpc-prod-ap-south-1"
    Name        = "preva-clothing-vpc-${var.environment}-${var.aws_region}"
    Environment = var.environment
  }
}

# 3. Attach an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    # 🟢 Dynamic Naming: "preva-clothing-igw-prod-ap-south-1"
    Name        = "preva-clothing-igw-${var.environment}-${var.aws_region}"
    Environment = var.environment
  }
}

# 4. Create a Public Subnet (Dynamically targets the 'a' zone of the active region)
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  
  # 🟢 Dynamic Availability Zone: becomes "ap-south-1a" or "us-east-1a"
  availability_zone = "${var.aws_region}a"

  # 🟢 CHANGED: Stop assigning non-elastic public IPs automatically
  map_public_ip_on_launch = false 

  tags = {
    # 🟢 Dynamic Naming: "preva-clothing-public-subnet-1a-prod"
    Name        = "preva-clothing-public-subnet-1a-${var.environment}"
    Environment = var.environment
  }
}

# 5. Create a Route Table pointing outbound internet traffic to the Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    # 🟢 Dynamic Naming: "preva-clothing-public-rt-prod-ap-south-1"
    Name        = "preva-clothing-public-rt-${var.environment}-${var.aws_region}"
    Environment = var.environment
  }
}

# 6. Bind the public subnet explicitly to the internet route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- OUTPUTS ---
output "vpc_id" {
  value       = aws_vpc.custom_vpc.id
  description = "The ID of the custom VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "The ID of the public subnet"
}
