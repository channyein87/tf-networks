module "vpc" {
  source = "../"

  profile     = "kbprod"
  environment = "prod"
  cidr        = "10.8.0.0/16"
  public-subnets = {
    ap-southeast-2a = "10.8.101.0/24"
    ap-southeast-2b = "10.8.102.0/24"
  }
  private-subnets = {
    ap-southeast-2a = "10.8.1.0/24"
    ap-southeast-2b = "10.8.2.0/24"
  }
  attach-subnets = {
    ap-southeast-2a = "10.8.201.0/24"
    ap-southeast-2b = "10.8.202.0/24"
  }
}

output "ec2_ip" {
  value = module.vpc.ec2_ip
}

output "ec2_id" {
  value = module.vpc.ec2_id
}
