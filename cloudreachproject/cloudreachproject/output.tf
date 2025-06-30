
#########################################################
# OUTPUT BLOCK
#########################################################
output "frontend_subnet_ids" {
  value = try(aws_subnet.frontend_subnet[*].id, "")
}

output "backend_subnet_id" {
  value = try(aws_subnet.backend_subnet[*].id, "")
}

output "igw_id" {
  value = try(aws_internet_gateway.igw.id, "")
}

output "ngw_id" {
  value = try(aws_nat_gateway.ngw[*].id, "")
}