provider "aws" {
  region  = "eu-west-2"
  profile = "cnnn"
}

data "aws_vpc" "default" {
  id = "vpc-ea3c5d82"
}

data "aws_subnet" "subnet" {
  id = "subnet-a2305bcb"
}

data "aws_security_group" "chko_vpn_sg" {
  id = "sg-0b91723f9f54888d9"
}

data "aws_acm_certificate" "server" {
  domain = "server"
}

data "aws_acm_certificate" "client" {
  domain = "client1.sandpit.click"
}

resource "aws_ec2_client_vpn_endpoint" "p2s" {
  description            = "chko-vpn"
  server_certificate_arn = data.aws_acm_certificate.server.arn
  client_cidr_block      = "192.168.100.0/22"
  dns_servers            = ["172.31.0.2"]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = data.aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_ec2_client_vpn_network_association" "subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.p2s.id
  subnet_id              = data.aws_subnet.subnet.id
  security_groups        = [data.aws_security_group.chko_vpn_sg.id]
}

resource "aws_ec2_client_vpn_route" "route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.p2s.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.subnet.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.p2s.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

output "vpn_dns" {
  description = "The DNS of the VPN"
  value       = aws_ec2_client_vpn_endpoint.p2s.dns_name
}
