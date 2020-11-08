module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name

  cidr = var.cidr

  azs             = var.azs[var.region]
  private_subnets = var.private-subnets[var.region]
  public_subnets  = var.public-subnets[var.region]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.environment
  }

  vpc_tags = {
    Name = "${var.name}-vpc"
  }

  enable_s3_endpoint = true
}
