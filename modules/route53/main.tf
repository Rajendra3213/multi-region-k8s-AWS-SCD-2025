data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_health_check" "primary" {
  fqdn                            = var.primary_endpoint
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = var.health_check_path
  failure_threshold               = "3"
  request_interval                = "30"
  insufficient_data_health_status = "Failure"

  tags = merge(var.tags, {
    Name = "primary-health-check"
  })
}

resource "aws_route53_health_check" "secondary" {
  fqdn                            = var.secondary_endpoint
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = var.health_check_path
  failure_threshold               = "3"
  request_interval                = "30"
  insufficient_data_health_status = "Failure"

  tags = merge(var.tags, {
    Name = "secondary-health-check"
  })
}

resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id
  set_identifier  = "primary"
  records         = [var.primary_ip]
}

resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.secondary.id
  set_identifier  = "secondary"
  records         = [var.secondary_ip]
}