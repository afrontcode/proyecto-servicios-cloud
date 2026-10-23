output "vpc_id" {
  description = "ID de la VPC del laboratorio."
  value       = try(aws_vpc.finops[0].id, null)
}

output "app_subnet_id" {
  description = "Subred privada de APP. Es la que debe usar src/seed.py."
  value       = try(aws_subnet.app[0].id, null)
}

output "data_subnet_id" {
  description = "Subred privada de DATA."
  value       = try(aws_subnet.data[0].id, null)
}

output "public_subnet_ids" {
  description = "Subredes publicas (alojan el NAT Gateway)."
  value       = compact([try(aws_subnet.public_a[0].id, ""), try(aws_subnet.public_b[0].id, "")])
}

output "app_security_group_id" {
  description = "SG de APP. Es el unico origen permitido hacia PostgreSQL."
  value       = try(aws_security_group.app[0].id, null)
}

output "app_instance_id" {
  description = "ID de la EC2 de aplicacion."
  value       = try(aws_instance.app[0].id, null)
}

output "data_instance_id" {
  description = "ID de la EC2 de base de datos."
  value       = try(aws_instance.data[0].id, null)
}

output "postgres_ebs_id" {
  description = "ID del volumen EBS de datos de PostgreSQL."
  value       = try(aws_ebs_volume.postgres[0].id, null)
}

output "nat_gateway_id" {
  description = "ID del NAT Gateway. Si no es null, se esta facturando por hora."
  value       = try(aws_nat_gateway.nat[0].id, null)
}
