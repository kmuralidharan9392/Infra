# 1. Initialize your custom VPC Network space
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Allows AWS to assign readable domain strings to your EC2 instance
  enable_dns_support   = true

  tags = {
    Name = "preva-clothing-vpc-prod"
  }
}

# 2. Attach an Internet Gateway (100% Free Doorway to the outside world)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "preva-clothing-igw-prod"
  }
}

# 3. Create a Public Subnet inside Mumbai's availability zone 'ap-south-1a'
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  # Crucial: Automatically maps a free dynamic public internet IP to any machine dropped here
  map_public_ip_on_launch = true 

  tags = {
    Name = "preva-clothing-public-subnet-1a"
  }
}

# 4. Create a Route Table pointing outbound internet traffic to the Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Targets all external web addresses
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "preva-clothing-public-rt"
  }
}

# 5. Bind the public subnet explicitly to the internet route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- OUTPUTS (Exposed so your upcoming EC2 workspace can read them automatically) ---
output "vpc_id" {
  value       = aws_vpc.custom_vpc.id
  description = "The ID of the custom VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "The ID of the public subnet"
}
