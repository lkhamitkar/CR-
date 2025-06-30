
env       = "prod"
component = "3-tier-architecture"

# VPC VARIABLE 
vpc_cidr             = "10.0.0.0/16"
frontend_subnet_cidr = ["10.0.0.0/24", "10.0.2.0/24"]
backend_subnet_cidr  = ["10.0.1.0/24", "10.0.3.0/24"]
database_subnet_cidr = ["10.0.51.0/24", "10.0.53.0/24"]

