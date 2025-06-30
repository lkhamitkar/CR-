

#########################################################
# TERRAFORM BLOCK
#########################################################

terraform {
  required_version = ">=1.1.0"

  # You can either use remote backend or remove this block entirely
  # backend "s3" {
  #   bucket         = "bucket_name" # specify your own bucket
  #   key            = "path/env" # path to store the state file
  #   region         = "eu-west-2"
  #   dynamodb_table = "terraform-lock" # specify your own dynamodb_table
  #   encrypt        = true

  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#########################################################
# PROVIDER BLOCK
#########################################################

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      env       = var.env
      component = var.component
    }

  }
}

#########################################################
# LOCAL BLOCK
#########################################################

locals {
  vpc_id = aws_vpc.prod_vpc.id
  azs    = slice(data.aws_availability_zones.available.names, 0, 2)
}

#########################################################
# DATA SOURCE BLOCK
#########################################################
data "aws_availability_zones" "available" {
  state = "available"

}

#########################################################
# VPC RESOURCE
#########################################################
resource "aws_vpc" "prod_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

}

#########################################################
# INTERNET GATEWAY RESOURCE
#########################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = local.vpc_id

  tags = {
    Name = "prod_igw"
  }
}

#########################################################
# PUBLIC SUBNET RESOURCE
#########################################################
resource "aws_subnet" "frontend_subnet" {
  count = length(var.frontend_subnet_cidr)

  vpc_id                  = local.vpc_id
  cidr_block              = var.frontend_subnet_cidr[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "frontend_subnet_${count.index + 1}"
  }
}

#########################################################
# BACKEND SUBNET RESOURCE
#########################################################
resource "aws_subnet" "backend_subnet" {
  count = length(var.backend_subnet_cidr)

  vpc_id            = local.vpc_id
  cidr_block        = var.backend_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "backend_subnet_${count.index + 1}"
  }
}

#########################################################
# DATABASE SUBNET RESOURCE
#########################################################
resource "aws_subnet" "database_subnet" {
  count = length(var.database_subnet_cidr)

  vpc_id            = local.vpc_id
  cidr_block        = var.database_subnet_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "database_subnet_${count.index + 1}"
  }
}

#########################################################
# PUBLIC ROUTE TABLE
#########################################################
resource "aws_route_table" "frontend_route_table" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "frontend_route_table"
  }
}

#########################################################
# DEFAULT ROUTE TABLE
#########################################################
resource "aws_default_route_table" "private_default_rt_table" {
  default_route_table_id = aws_vpc.prod_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = try(aws_nat_gateway.ngw[0].id, "")
  }

  tags = {
    Name = "prod_default_rt_table"
  }
}

#########################################################
# PUBLIC ROUTE TABLE ASSOCIATION 
#########################################################

resource "aws_route_table_association" "public_rt_table" {
  count = length(aws_subnet.frontend_subnet)

  subnet_id      = aws_subnet.frontend_subnet[count.index].id
  route_table_id = aws_route_table.frontend_route_table.id
}

#########################################################
# NAT GATEWAY
#########################################################

resource "aws_nat_gateway" "ngw" {
  count      = length(var.frontend_subnet_cidr) > 0 ? 1 : 0
  depends_on = [aws_internet_gateway.igw]

  allocation_id = try(aws_eip.eip[0].id, "")
  subnet_id     = try(aws_subnet.frontend_subnet[0].id, "")

  tags = {
    Name = "prod_nat_gw"
  }

}

#########################################################
# ELASTIC IP
#########################################################

resource "aws_eip" "eip" {
  count      = length(var.frontend_subnet_cidr) > 0 ? 1 : 0
  depends_on = [aws_internet_gateway.igw]

  vpc = true
}