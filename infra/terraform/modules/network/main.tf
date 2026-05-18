locals {
  public_subnets = {
    for index, cidr_block in var.public_subnet_cidrs : tostring(index) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr_block
      name              = format("%s-public-%02d", var.name_prefix, index + 1)
    }
  }

  private_subnets = {
    for index, cidr_block in var.private_subnet_cidrs : tostring(index) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr_block
      name              = format("%s-private-%02d", var.name_prefix, index + 1)
    }
  }

  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "network"
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-vpc"
  })

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_cidrs) == length(var.private_subnet_cidrs)
      error_message = "public_subnet_cidrs and private_subnet_cidrs must contain the same number of entries."
    }

    precondition {
      condition     = length(var.availability_zones) >= length(var.public_subnet_cidrs)
      error_message = "availability_zones must contain at least as many entries as subnet CIDR lists."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.component_tags, {
    Name = each.value.name
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.component_tags, {
    Name = each.value.name
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["0"].id

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(local.component_tags, {
    Name = format("%s-private-%02d-rt", var.name_prefix, tonumber(each.key) + 1)
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
