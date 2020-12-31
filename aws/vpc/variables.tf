variable "region" {
    type = string
    default = "ap-southeast-2"
}

variable "profile" {
    type = string
    default = "kbshared"
}

variable "prefix" {
    type = string
    default = "tf"
}

variable "environment" {
    type = string
    default = "shared"
}

variable "cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public-subnets" {
    default = {
        ap-southeast-2a = "10.0.101.0/24"
        ap-southeast-2b = "10.0.102.0/24"
    }
}

variable "private-subnets" {
    default = {
        ap-southeast-2a = "10.0.1.0/24"
        ap-southeast-2b = "10.0.2.0/24"
    }
}

variable "attach-subnets" {
    default = {
        ap-southeast-2a = "10.0.201.0/24"
        ap-southeast-2b = "10.0.202.0/24"
    }
}
