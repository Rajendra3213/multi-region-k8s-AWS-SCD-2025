resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.accelerator_name
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = var.flow_logs_enabled
    flow_logs_s3_bucket = var.flow_logs_s3_bucket
    flow_logs_s3_prefix = var.flow_logs_s3_prefix
  }

  tags = var.tags
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_group_region   = var.primary_region
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = var.primary_nlb_arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_group_region   = var.secondary_region
  traffic_dial_percentage = 0

  endpoint_configuration {
    endpoint_id = var.secondary_nlb_arn
    weight      = 100
  }
}