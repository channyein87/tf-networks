variable "region" {
    type = string
    default = "ap-southeast-2"
}

variable "profile" {
    type = string
    default = "kbprod"
}

variable "prefix" {
    type = string
    default = "tf"
}

variable "environment" {
    type = string
    default = "prod"
}

variable "cidr" {
    type = string
    default = "10.8.0.0/16"
}

variable "public-subnets" {
    default = {
        ap-southeast-2a = "10.8.101.0/24"
        ap-southeast-2b = "10.8.102.0/24"
    }
}

variable "private-subnets" {
    default = {
        ap-southeast-2a = "10.8.1.0/24"
        ap-southeast-2b = "10.8.2.0/24"
    }
}

variable "attach-subnets" {
    default = {
        ap-southeast-2a = "10.8.201.0/24"
        ap-southeast-2b = "10.8.202.0/24"
    }
}
