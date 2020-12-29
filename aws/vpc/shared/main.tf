resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-vpc"
    "Environment" = var.environment
  }
}

resource "aws_subnet" "public" {
  for_each = var.public-subnets

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-public-${substr(each.key, -1, 1)}"
    "Environment" = var.environment
    "Tier"        = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private-subnets

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-private-${substr(each.key, -1, 1)}"
    "Environment" = var.environment
    "Tier"        = "private"
  }
}

resource "aws_subnet" "attach" {
  for_each = var.attach-subnets

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-attach-${substr(each.key, -1, 1)}"
    "Environment" = var.environment
    "Tier"        = "attach"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-public-rt"
    "Environment" = var.environment
    "Tier"        = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-private-rt"
    "Environment" = var.environment
    "Tier"        = "private"
  }
}

resource "aws_route_table" "attach" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-attach-rt"
    "Environment" = var.environment
    "Tier"        = "attach"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "attach" {
  for_each = aws_subnet.attach

  subnet_id      = aws_subnet.attach[each.key].id
  route_table_id = aws_route_table.attach.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-igw"
    "Environment" = var.environment
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_eip" "nat_eip" {
  tags = {
    "Name" = "${var.prefix}-${var.environment}-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[keys(var.public-subnets)[0]].id

  tags = {
    "Name" = "${var.prefix}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route" "attach" {
  route_table_id         = aws_route_table.attach.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_security_group" "sg" {
  name        = "${var.prefix}-${var.environment}-ec2-sg"
  description = "${var.prefix}-${var.environment}-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow ping."
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.prefix}-${var.environment}-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.private[keys(var.private-subnets)[0]].id
  key_name               = aws_key_pair.key_pair.key_name
}
