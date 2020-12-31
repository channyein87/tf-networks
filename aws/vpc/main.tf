resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

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
  count = var.environment == "shared" ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"        = "${var.prefix}-${var.environment}-igw"
    "Environment" = var.environment
  }
}

resource "aws_route" "public" {
  count = var.environment == "shared" ? 1 : 0

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[count.index].id
}

resource "aws_eip" "nat_eip" {
  count = var.environment == "shared" ? 1 : 0

  tags = {
    "Name" = "${var.prefix}-${var.environment}-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  count = var.environment == "shared" ? 1 : 0

  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[keys(var.public-subnets)[0]].id

  tags = {
    "Name" = "${var.prefix}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private" {
  count = var.environment == "shared" ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route" "attach" {
  count = var.environment == "shared" ? 1 : 0

  route_table_id         = aws_route_table.attach.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_vpc_endpoint" "s3" {
  service_name    = "com.amazonaws.${var.region}.s3"
  vpc_id          = aws_vpc.vpc.id
  route_table_ids = [aws_route_table.private.id]
}

resource "aws_security_group" "vpce" {
  name        = "${var.prefix}-${var.environment}-vpce-sg"
  description = "${var.prefix}-${var.environment}-vpce-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "kms" {
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_id              = aws_vpc.vpc.id
  security_group_ids  = [aws_security_group.vpce.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

resource "aws_vpc_endpoint_subnet_association" "kms_subnet" {
  for_each = aws_subnet.private

  vpc_endpoint_id = aws_vpc_endpoint.kms.id
  subnet_id       = each.value.id
}

resource "aws_iam_role" "ec2" {
  name = "${var.prefix}-${var.environment}-ec2-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.prefix}-${var.environment}-ec2-role"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_security_group" "ec2" {
  name        = "${var.prefix}-${var.environment}-ec2-sg"
  description = "${var.prefix}-${var.environment}-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
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

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "ec2" {
  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.private[keys(var.private-subnets)[0]].id
  key_name               = aws_key_pair.key_pair.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
}
