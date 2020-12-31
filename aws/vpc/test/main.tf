module "vpc" {
  source = "../"

  profile     = "kbtest"
  environment = "test"
  cidr        = "10.17.0.0/16"
  public-subnets = {
    ap-southeast-2a = "10.17.101.0/24"
    ap-southeast-2b = "10.17.102.0/24"
  }
  private-subnets = {
    ap-southeast-2a = "10.17.1.0/24"
    ap-southeast-2b = "10.17.2.0/24"
  }
  attach-subnets = {
    ap-southeast-2a = "10.17.201.0/24"
    ap-southeast-2b = "10.17.202.0/24"
  }
}

output "ec2_ip" {
  value = module.vpc.ec2_ip
}

output "ec2_id" {
  value = module.vpc.ec2_id
}
