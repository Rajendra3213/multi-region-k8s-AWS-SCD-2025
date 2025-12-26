output "transit_gateway_id" {
  description = "EC2 Transit Gateway identifier"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "EC2 Transit Gateway Amazon Resource Name (ARN)"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_association_default_route_table_id" {
  description = "Identifier of the default association route table"
  value       = aws_ec2_transit_gateway.main.association_default_route_table_id
}

output "transit_gateway_propagation_default_route_table_id" {
  description = "Identifier of the default propagation route table"
  value       = aws_ec2_transit_gateway.main.propagation_default_route_table_id
}

output "vpc_attachment_ids" {
  description = "List of EC2 Transit Gateway VPC Attachment identifiers"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.main : k => v.id }
}