output "primary_cluster_endpoint" {
  description = "Endpoint for EKS control plane in primary region"
  value       = module.eks_primary.cluster_endpoint
}

output "secondary_cluster_endpoint" {
  description = "Endpoint for EKS control plane in secondary region"
  value       = module.eks_secondary.cluster_endpoint
}

output "primary_cluster_name" {
  description = "EKS cluster name in primary region"
  value       = module.eks_primary.cluster_id
}

output "secondary_cluster_name" {
  description = "EKS cluster name in secondary region"
  value       = module.eks_secondary.cluster_id
}

output "primary_vpc_id" {
  description = "VPC ID in primary region"
  value       = module.vpc_primary.vpc_id
}

output "secondary_vpc_id" {
  description = "VPC ID in secondary region"
  value       = module.vpc_secondary.vpc_id
}

output "transit_gateway_primary_id" {
  description = "Transit Gateway ID in primary region"
  value       = module.transit_gateway_primary.transit_gateway_id
}

output "transit_gateway_secondary_id" {
  description = "Transit Gateway ID in secondary region"
  value       = module.transit_gateway_secondary.transit_gateway_id
}

output "peering_attachment_id" {
  description = "Transit Gateway peering attachment ID"
  value       = aws_ec2_transit_gateway_peering_attachment.primary_to_secondary.id
}
output "global_accelerator_dns" {
  description = "Global Accelerator DNS name"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "global_accelerator_ips" {
  description = "Global Accelerator static IPs"
  value       = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = data.aws_route53_zone.main.name_servers
}

output "application_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}