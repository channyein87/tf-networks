module "vpc" {
  source = "../"

  profile     = "kbshared"
  environment = "shared"
  cidr        = "10.0.0.0/16"
  public-subnets = {
    ap-southeast-2a = "10.0.101.0/24"
    ap-southeast-2b = "10.0.102.0/24"
  }
  private-subnets = {
    ap-southeast-2a = "10.0.1.0/24"
    ap-southeast-2b = "10.0.2.0/24"
  }
  attach-subnets = {
    ap-southeast-2a = "10.0.201.0/24"
    ap-southeast-2b = "10.0.202.0/24"
  }
}

output "ec2_ip" {
  value = module.vpc.ec2_ip
}

output "ec2_id" {
  value = module.vpc.ec2_id
}
