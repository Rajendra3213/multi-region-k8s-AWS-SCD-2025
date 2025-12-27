terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  regions = {
    primary   = var.primary_region
    secondary = var.secondary_region
  }
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Primary Region Provider
provider "aws" {
  alias  = "primary"
  region = local.regions.primary
}

# Secondary Region Provider
provider "aws" {
  alias  = "secondary"
  region = local.regions.secondary
}

# Primary Region VPC
module "vpc_primary" {
  source = "../modules/vpc"
  providers = {
    aws = aws.primary
  }

  name_prefix           = "primary-region"
  vpc_cidr              = var.primary_vpc_cidr
  private_subnet_count  = 3
  public_subnet_count   = 3
  enable_nat_gateway    = true
  nat_gateway_count     = 3
  
  tags = local.common_tags
}

# Secondary Region VPC
module "vpc_secondary" {
  source = "../modules/vpc"
  providers = {
    aws = aws.secondary
  }

  name_prefix           = "secondary-region"
  vpc_cidr              = var.secondary_vpc_cidr
  private_subnet_count  = 3
  public_subnet_count   = 3
  enable_nat_gateway    = true
  nat_gateway_count     = 3
  
  tags = local.common_tags
}

# Primary Region EKS Cluster
module "eks_primary" {
  source = "../modules/eks"
  providers = {
    aws = aws.primary
  }

  cluster_name                        = "primary-cluster"
  cluster_version                     = var.kubernetes_version
  vpc_id                              = module.vpc_primary.vpc_id
  subnet_ids                          = concat(module.vpc_primary.private_subnet_ids, module.vpc_primary.public_subnet_ids)
  private_subnet_ids                  = module.vpc_primary.private_subnet_ids
  cluster_endpoint_private_access     = true
  cluster_endpoint_public_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  
  node_group_instance_types = var.node_instance_types
  node_group_desired_size   = var.node_desired_size
  node_group_max_size       = var.node_max_size
  node_group_min_size       = var.node_min_size
  
  tags = local.common_tags
}

# Secondary Region EKS Cluster
module "eks_secondary" {
  source = "../modules/eks"
  providers = {
    aws = aws.secondary
  }

  cluster_name                        = "secondary-cluster"
  cluster_version                     = var.kubernetes_version
  vpc_id                              = module.vpc_secondary.vpc_id
  subnet_ids                          = concat(module.vpc_secondary.private_subnet_ids, module.vpc_secondary.public_subnet_ids)
  private_subnet_ids                  = module.vpc_secondary.private_subnet_ids
  cluster_endpoint_private_access     = true
  cluster_endpoint_public_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  
  node_group_instance_types = var.node_instance_types
  node_group_desired_size   = var.node_desired_size
  node_group_max_size       = var.node_max_size
  node_group_min_size       = var.node_min_size
  
  tags = local.common_tags
}

# Transit Gateway in Primary Region
module "transit_gateway_primary" {
  source = "../modules/transit-gateway"
  providers = {
    aws = aws.primary
  }

  name        = "primary-tgw"
  description = "Transit Gateway for multi-region EKS connectivity"
  
  vpc_attachments = {
    primary = {
      vpc_id     = module.vpc_primary.vpc_id
      subnet_ids = module.vpc_primary.private_subnet_ids
    }
  }
  
  vpc_routes = {
    to_secondary = {
      route_table_id         = module.vpc_primary.private_route_table_ids[0]
      destination_cidr_block = module.vpc_secondary.vpc_cidr_block
    }
  }
  
  tags = local.common_tags
}

# Transit Gateway in Secondary Region
module "transit_gateway_secondary" {
  source = "../modules/transit-gateway"
  providers = {
    aws = aws.secondary
  }

  name        = "secondary-tgw"
  description = "Transit Gateway for multi-region EKS connectivity"
  
  vpc_attachments = {
    secondary = {
      vpc_id     = module.vpc_secondary.vpc_id
      subnet_ids = module.vpc_secondary.private_subnet_ids
    }
  }
  
  vpc_routes = {
    to_primary = {
      route_table_id         = module.vpc_secondary.private_route_table_ids[0]
      destination_cidr_block = module.vpc_primary.vpc_cidr_block
    }
  }
  
  tags = local.common_tags
}

# Transit Gateway Peering Connection
resource "aws_ec2_transit_gateway_peering_attachment" "primary_to_secondary" {
  provider = aws.primary
  
  peer_region             = local.regions.secondary
  peer_transit_gateway_id = module.transit_gateway_secondary.transit_gateway_id
  transit_gateway_id      = module.transit_gateway_primary.transit_gateway_id
  
  tags = merge(local.common_tags, {
    Name = "primary-to-secondary-peering"
  })
}

# Accept peering connection in secondary region
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "secondary_accept" {
  provider = aws.secondary
  
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.primary_to_secondary.id
  
  tags = merge(local.common_tags, {
    Name = "secondary-accept-peering"
  })
}

# Global Accelerator
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "multi-region-accelerator"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled = false
  }

  tags = local.common_tags
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

# Note: After deploying K8s service, get NLB ARNs and update endpoint_id below
# Run: ./get-nlb-arns.sh
resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_group_region   = local.regions.primary
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = "arn:aws:elasticloadbalancing:ap-south-1:488309743291:loadbalancer/net/aabba6d93484e41c5b7b2c59b502acdf/27740130f7be85f2"
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn = aws_globalaccelerator_listener.main.id

  endpoint_group_region   = local.regions.secondary
  traffic_dial_percentage = 0

  endpoint_configuration {
    endpoint_id = "arn:aws:elasticloadbalancing:ap-northeast-1:488309743291:loadbalancer/net/a4d05e2b4ae6f4a359f36484771f4c90/84bfb496c79a3373"
    weight      = 100
  }
}

# Use existing Route53 Hosted Zone
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# Route53 Record pointing to Global Accelerator
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_globalaccelerator_accelerator.main.dns_name
    zone_id                = aws_globalaccelerator_accelerator.main.hosted_zone_id
    evaluate_target_health = true
  }
}