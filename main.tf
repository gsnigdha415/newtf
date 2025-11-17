terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider

provider "aws" {
  region = "us-east-1"
}

# Create a VPC

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

   tags = {
    Name = "main_vpc"
  }
}

# Create a Public Subnet

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "my-public-subnet"
  }
}

# Create a Private Subnet

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a" 
  map_public_ip_on_launch = false
  tags = {
    Name = "my-private-subnet"
  }
}

#create a IGW

resource "aws_internet_gateway" "demo-vpc-igw" {
 vpc_id = aws_vpc.main_vpc.id
 
 tags = {
   Name = "demo-vpc-igw"
 }
}

#NAT Gateway

resource "aws_eip" "nat_eip" {
}
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.demo-vpc-igw]
  tags = { Name = "NAT gw" }
}

#public Routetable

resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main_vpc.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.demo-vpc-igw.id
 }
 
 tags = {
   Name = "public Route Table"
 }
}

#aws public route table association

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#private routetable

resource "aws_route_table" "private_rt" {
 vpc_id = aws_vpc.main_vpc.id
 
 route {
   cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.natgw.id
 }
 
 tags = {
   Name = "private Route Table"
 }
}

#aws private route table association

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

#Creating SG's

resource "aws_security_group" "demo-vpc-sg" {
  name        = "demo-vpc-sg"
  vpc_id      = aws_vpc.main_vpc.id
 
  ingress {
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
}

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1" 
    cidr_blocks         = ["0.0.0.0/0"]
    
 }
}

#Creating EC2 instance

    resource "aws_instance" "terraform_instance" {
      ami           = "ami-0ecb62995f68bb549" 
      instance_type = "t2.micro"
      key_name      = "new" 
      tags = {
        Name = "MyTerraformEC2"
      }
    }