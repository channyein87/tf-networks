resource "aws_vpc" "shared" {
  cidr_block = var.cidr

  tags = {
    "Name" = "${var.prefix}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = var.public-subnets

  vpc_id = aws_vpc.shared.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    "Name" = "${var.prefix}-${var.environment}-public-${substr(each.key, -1, 1)}"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private-subnets

  vpc_id = aws_vpc.shared.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    "Name" = "${var.prefix}-${var.environment}-private-${substr(each.key, -1, 1)}"
  }
}

resource "aws_subnet" "attach" {
  for_each = var.attach-subnets

  vpc_id = aws_vpc.shared.id
  availability_zone = each.key
  cidr_block = each.value

  tags = {
    "Name" = "${var.prefix}-${var.environment}-attach-${substr(each.key, -1, 1)}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shared.id

  tags = {
    "Name" = "${var.prefix}-${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.shared.id

  tags = {
    "Name" = "${var.prefix}-${var.environment}-private-rt"
  }
}

resource "aws_route_table" "attach" {
  vpc_id = aws_vpc.shared.id

  tags = {
    "Name" = "${var.prefix}-${var.environment}-attach-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "attach" {
  for_each = aws_subnet.attach

  subnet_id = aws_subnet.attach[each.key].id
  route_table_id = aws_route_table.attach.id
}
