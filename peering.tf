## VPC peering connection from expense vpc to deffault vpc
resource "aws_vpc_peering_connection" "default" {
  count = var.is_peering_required ? 1 : 0
  

  peer_vpc_id   = aws_vpc.main.id   # Requester vpc id
  vpc_id        = local.default_vpc_id  # Accepter 
  auto_accept = true

  tags = merge(
    var.common_tags,
    var.vpc_peering_tags,
    {
        Name = "${local.resource_name}-default"
    }
  )
} 

resource "aws_route" "public_peering" {
    count = var.is_peering_required ? 1 : 0
    route_table_id = aws_route_table.public.id
    destination_cidr_block = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
  
}

resource "aws_route" "private_peering" {
    count = var.is_peering_required ? 1 : 0
    route_table_id = aws_route_table.private.id
    destination_cidr_block = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
  
}

resource "aws_route" "database_peering" {
    count = var.is_peering_required ? 1 : 0
    route_table_id = aws_route_table.database.id
    destination_cidr_block = local.default_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
  
}

resource "aws_route" "default_peering" {
    count = var.is_peering_required ? 1 : 0
    route_table_id = data.aws_route_table.main.id
    destination_cidr_block = var.vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
  
}