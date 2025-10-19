output "network" {
  description = "The VPC resource"
  value       = module.vpc.network
}

output "network_name" {
  description = "The name of the VPC"
  value       = module.vpc.network_name
}

output "network_self_link" {
  description = "The URI of the VPC"
  value       = module.vpc.network_self_link
}

output "subnets" {
  description = "The created subnet resources"
  value       = module.vpc.subnets
}

output "subnets_secondary_ranges" {
  description = "The secondary ranges of the subnets"
  value       = module.vpc.subnets_secondary_ranges
}

output "network_id" {
  description = "The network ID"
  value       = module.vpc.network_id
}

output "public_subnet_name" {
  description = "The name of the public subnet"
  value       = module.vpc.subnets["${var.region}/${var.network_name}-public"].name
}

output "private_subnet_name" {
  description = "The name of the private subnet"
  value       = module.vpc.subnets["${var.region}/${var.network_name}-private"].name
}
