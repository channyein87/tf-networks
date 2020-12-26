variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "profile" {
  type    = string
  default = "kbtest"
}

variable "prefix" {
  type    = string
  default = "tf"
}

variable "environment" {
  type    = string
  default = "test"
}

variable "cidr" {
  type    = string
  default = "10.17.0.0/16"
}

variable "public-subnets" {
  default = {
    ap-southeast-2a = "10.17.101.0/24"
    ap-southeast-2b = "10.17.102.0/24"
  }
}

variable "private-subnets" {
  default = {
    ap-southeast-2a = "10.17.1.0/24"
    ap-southeast-2b = "10.17.2.0/24"
  }
}

variable "attach-subnets" {
  default = {
    ap-southeast-2a = "10.17.201.0/24"
    ap-southeast-2b = "10.17.202.0/24"
  }
}
