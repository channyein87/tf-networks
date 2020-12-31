data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

resource "aws_security_group" "sg" {
  name        = "${var.prefix}-${var.environment}-r53resolver-sg"
  description = "${var.prefix}-${var.environment}-r53resolver-sg"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "dns" {
  for_each = toset(["TCP", "UDP"])

  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = each.value
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_route53_resolver_endpoint" "outbound" {
  name               = "${var.prefix}-${var.environment}-outbound-endpoint"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.sg.id]

  dynamic "ip_address" {
    for_each = data.aws_subnet_ids.subnets.ids

    content {
      subnet_id = ip_address.value
    }
  }
}

resource "aws_route53_resolver_rule" "forward" {
  name                 = "${var.prefix}-${var.environment}-forward-rule"
  domain_name          = var.onprem-dns-name
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  dynamic "target_ip" {
    for_each = var.onprem-dns-ips

    content {
      ip = target_ip.value
    }
  }
}

resource "aws_route53_resolver_rule_association" "onprem_dns" {
  resolver_rule_id = aws_route53_resolver_rule.forward.id
  vpc_id           = data.aws_vpc.vpc.id
}
