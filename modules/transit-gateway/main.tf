resource "aws_ec2_transit_gateway" "main" {
  description                     = var.description
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  for_each           = var.vpc_attachments
  subnet_ids         = each.value.subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = each.value.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  count              = var.create_route_table ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-rt"
  })
}

resource "aws_ec2_transit_gateway_route" "main" {
  for_each                       = var.routes
  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main[each.value.attachment_key].id
  transit_gateway_route_table_id = var.create_route_table ? aws_ec2_transit_gateway_route_table.main[0].id : aws_ec2_transit_gateway.main.association_default_route_table_id
}

resource "aws_route" "tgw_routes" {
  for_each               = var.vpc_routes
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}