# Expense Project VPC 
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  enable_dns_hostnames = var.enabled_dns_hostname
  instance_tenancy = "default"

# expense-dev
  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
          Name = local.resource_name
    }
  )
}

# Internet gateway for the expenese Project 
  resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.igw_tags,
   {
    Name = local.resource_name
     }
  )
  }
/* #Expense dev-us-east-a subnet
  resource "aws_subnet" "main" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    var.public_subnet_tags,
       {
        Name = "${local.resource_name}-public-${local.az_names[count.index]}"
       }
  )
} */

#Expense dev-us-east-a public subnet

  resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    var.public_subnet_tags,
       {
        Name = "${local.resource_name}-public-${local.az_names[count.index]}"
       }
  )
}
#Expense dev-us-east-a private subnet
  resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_tags,
       {
        Name = "${local.resource_name}-private-${local.az_names[count.index]}"
       }
  )
}

#Expense dev-us-east-a Database subnet
  resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]

  tags = merge(
    var.common_tags,
    var.database_subnet_tags,
       {
        Name = "${local.resource_name}-database-${local.az_names[count.index]}"
       }
  )
}

# Assgining elastic IP addrress for the NAT Gateway

resource "aws_eip" "nat" {
  domain   = "vpc"
}

 # NAT Gateway

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    var.nat_gateway_tags,
    {
        Name = local.resource_name
    }
  )
depends_on = [aws_internet_gateway.main]
}

# Route tables public 

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.public_route_table_tags,

    {
        Name = "${local.resource_name}-public"
    }
  )

}

# Route table private 
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.private_route_table_tags,

    {
        Name = "${local.resource_name}-private"
    }
  )

}


# Route table private 
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.database_route_table_tags,

    {
        Name = "${local.resource_name}-database"
    }
  )

}

## Public Route via internet gateway
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

## Private Route via NAT gateway
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.example.id
}

## Public Route via NAT gateway
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.example.id
}

## Public route table association 

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

## Private route table association 

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

## Database route table association 

resource "aws_route_table_association" "database" {
  count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
