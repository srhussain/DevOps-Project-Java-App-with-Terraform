output "vpc_id_bastion" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public.id
}

# output "private_subnet_ids" {
#   description = "List of private subnet IDs"
#   value       = aws_subnet.private[*].id
# }

# output "nat_gateway_ids" {
#   description = "List of NAT Gateway IDs"
#   value       = aws_nat_gateway.main[*].id
# }

output "vpc_cidr_bastion" {
  description = "CIDR block of the Bastion VPC"
  value       = aws_vpc.main.cidr_block
} 

output "public_route_table_id" {
  description = "Public route table ID for Bastion VPC"
  value       = aws_route_table.public.id
}
