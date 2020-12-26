resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = 65000
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    "Name" = "${var.prefix}-${var.environment}-tgw"
  }
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn    = 65500
  ip_address = var.onprem-ip
  type       = "ipsec.1"

  tags = {
    "Name" = "value"
  }
}

data "aws_caller_identity" "test" {
  provider = aws.test
}

data "aws_caller_identity" "dev" {
  provider = aws.dev
}

data "aws_caller_identity" "prod" {
  provider = aws.prod
}

resource "aws_ram_resource_share" "tgw" {
  name                      = "${var.prefix}-${var.environment}-tgw"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "test" {
  principal          = data.aws_caller_identity.test.account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ram_principal_association" "dev" {
  principal          = data.aws_caller_identity.dev.account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ram_principal_association" "prod" {
  principal          = data.aws_caller_identity.prod.account_id
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ram_resource_association" "tgw" {
  resource_arn       = aws_ec2_transit_gateway.tgw.arn
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ec2_transit_gateway_route_table" "green" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    "Name" = "tgw-green-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "red" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    "Name" = "tgw-red-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "blue" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  tags = {
    "Name" = "tgw-blue-rt"
  }
}

data "aws_vpc" "test" {
  provider = aws.test

  filter {
    name = "tag:Environment"
    value = ["test"]
  }
}

data "aws_subnet_ids" "test" {
  provider = aws.test

  vpc_id = data.aws_vpc.test.id

  filter {
    name = "tag:Tier"
    value = ["attach"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "test" {
  subnet_ids = [ data.aws_subnet_ids.test.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id = data.aws_vpc.test.id
}
