/*==================================
====== Transit Gateway Setup ======
==================================*/

resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn                 = 65000
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
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
    "Name" = "${var.prefix}-${var.environment}-cgw"
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

/*==================================
====== TEST Networks Setup ======
==================================*/

data "aws_vpc" "test" {
  provider = aws.test

  filter {
    name   = "tag:Environment"
    values = ["test"]
  }
}

data "aws_subnet_ids" "test" {
  provider = aws.test

  vpc_id = data.aws_vpc.test.id

  filter {
    name   = "tag:Tier"
    values = ["attach"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "test" {
  provider = aws.test

  subnet_ids         = data.aws_subnet_ids.test.ids
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.aws_vpc.test.id

  tags = {
    "Name" = "test-tgw-att"
  }

  depends_on = [
    aws_ram_principal_association.test,
    aws_ram_resource_association.tgw
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "test" {
  transit_gateway_attachment_id                   = aws_ec2_transit_gateway_vpc_attachment.test.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    "Name" = "test-tgw-att"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "test" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.test.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment_accepter.test]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "test_red" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.test.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.test]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "test_green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.test.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.test]
}

/*==================================
====== DEV Networks Setup ======
==================================*/

data "aws_vpc" "dev" {
  provider = aws.dev

  filter {
    name   = "tag:Environment"
    values = ["dev"]
  }
}

data "aws_subnet_ids" "dev" {
  provider = aws.dev

  vpc_id = data.aws_vpc.dev.id

  filter {
    name   = "tag:Tier"
    values = ["attach"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  provider = aws.dev

  subnet_ids         = data.aws_subnet_ids.dev.ids
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.aws_vpc.dev.id

  tags = {
    "Name" = "dev-tgw-att"
  }

  depends_on = [
    aws_ram_principal_association.dev,
    aws_ram_resource_association.tgw
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "dev" {
  transit_gateway_attachment_id                   = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    "Name" = "dev-tgw-att"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment_accepter.dev]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_red" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.dev]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.dev]
}

/*==================================
====== PROD Networks Setup ======
==================================*/

data "aws_vpc" "prod" {
  provider = aws.prod

  filter {
    name   = "tag:Environment"
    values = ["prod"]
  }
}

data "aws_subnet_ids" "prod" {
  provider = aws.prod

  vpc_id = data.aws_vpc.prod.id

  filter {
    name   = "tag:Tier"
    values = ["attach"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  provider = aws.prod

  subnet_ids         = data.aws_subnet_ids.prod.ids
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.aws_vpc.prod.id

  tags = {
    "Name" = "prod-tgw-att"
  }

  depends_on = [
    aws_ram_principal_association.prod,
    aws_ram_resource_association.tgw
  ]
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "prod" {
  transit_gateway_attachment_id                   = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    "Name" = "prod-tgw-att"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.blue.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment_accepter.prod]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod_blue" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.blue.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.prod]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod_green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.prod]
}

/*==================================
====== SHARED Networks Setup ======
==================================*/

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Environment"
    values = ["shared"]
  }
}

data "aws_subnet_ids" "shared" {
  vpc_id = data.aws_vpc.shared.id

  filter {
    name   = "tag:Tier"
    values = ["attach"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  subnet_ids                                      = data.aws_subnet_ids.shared.ids
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = data.aws_vpc.shared.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    "Name" = "shared-tgw-att"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.shared]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_red" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.shared]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_blue" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.blue.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.shared]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_green" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.shared]
}

resource "aws_ec2_transit_gateway_route" "default_red" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id
}

resource "aws_ec2_transit_gateway_route" "default_blue" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.blue.id
}

data "aws_route_table" "shared_public" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-${var.environment}-public-rt"]
  }
}

resource "aws_route" "nat" {
  destination_cidr_block = "10.0.0.0/8"
  route_table_id         = data.aws_route_table.shared_public.id
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

data "aws_route_table" "test_private" {
  provider = aws.test

  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-test-private-rt"]
  }
}

resource "aws_route" "test_default" {
  provider = aws.test

  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  route_table_id         = data.aws_route_table.test_private.id
}

data "aws_route_table" "dev_private" {
  provider = aws.dev

  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-dev-private-rt"]
  }
}

resource "aws_route" "dev_default" {
  provider = aws.dev

  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  route_table_id         = data.aws_route_table.dev_private.id
}

data "aws_route_table" "prod_private" {
  provider = aws.prod

  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-prod-private-rt"]
  }
}

resource "aws_route" "prod_default" {
  provider = aws.prod

  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  route_table_id         = data.aws_route_table.prod_private.id
}

/*=========================
====== TGW VPN Setup ======
==========================*/

resource "aws_vpn_connection" "vpn" {
  transit_gateway_id  = aws_ec2_transit_gateway.tgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"

  tunnel1_inside_cidr   = var.tunnel-1-cidr
  tunnel2_inside_cidr   = var.tunnel-2-cidr
  tunnel1_preshared_key = var.preshared-key
  tunnel2_preshared_key = var.preshared-key

  tags = {
    "Name" = "${var.prefix}-${var.environment}-vpn"
  }
}

data "aws_ec2_transit_gateway_vpn_attachment" "vpn_tgw" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpn_connection_id  = aws_vpn_connection.vpn.id
}

resource "aws_ec2_tag" "vpn_tgw" {
  resource_id = data.aws_ec2_transit_gateway_vpn_attachment.vpn_tgw.id
  key         = "Name"
  value       = "vpn-tgw-att"
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_vpn_connection.vpn]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_green" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.green.id

  depends_on = [aws_vpn_connection.vpn]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_red" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.red.id

  depends_on = [aws_vpn_connection.vpn]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_blue" {
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpn_attachment.vpn_tgw.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.blue.id

  depends_on = [aws_vpn_connection.vpn]
}
