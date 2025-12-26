output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Route53 name servers"
  value       = aws_route53_zone.main.name_servers
}

output "primary_health_check_id" {
  description = "Primary health check ID"
  value       = aws_route53_health_check.primary.id
}

output "secondary_health_check_id" {
  description = "Secondary health check ID"
  value       = aws_route53_health_check.secondary.id
}