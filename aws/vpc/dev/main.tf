module "vpc" {
  source = "../"

  profile     = "kbdev"
  environment = "dev"
  cidr        = "10.16.0.0/16"
  public-subnets = {
    ap-southeast-2a = "10.16.101.0/24"
    ap-southeast-2b = "10.16.102.0/24"
  }
  private-subnets = {
    ap-southeast-2a = "10.16.1.0/24"
    ap-southeast-2b = "10.16.2.0/24"
  }
  attach-subnets = {
    ap-southeast-2a = "10.16.201.0/24"
    ap-southeast-2b = "10.16.202.0/24"
  }
}

output "ec2_ip" {
  value = module.vpc.ec2_ip
}

output "ec2_id" {
  value = module.vpc.ec2_id
}
