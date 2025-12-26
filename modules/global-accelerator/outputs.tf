output "accelerator_id" {
  description = "Global Accelerator ID"
  value       = aws_globalaccelerator_accelerator.main.id
}

output "accelerator_arn" {
  description = "Global Accelerator ARN"
  value       = aws_globalaccelerator_accelerator.main.id
}

output "accelerator_dns_name" {
  description = "Global Accelerator DNS name"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "accelerator_hosted_zone_id" {
  description = "Global Accelerator hosted zone ID"
  value       = aws_globalaccelerator_accelerator.main.hosted_zone_id
}

output "static_ips" {
  description = "Static IP addresses"
  value       = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
}