variable "region" {
    type = string
    default = "ap-southeast-2"
}

variable "profile" {
    type = string
    default = "kbdev"
}

variable "prefix" {
    type = string
    default = "tf"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "cidr" {
    type = string
    default = "10.16.0.0/16"
}

variable "public-subnets" {
    default = {
        ap-southeast-2a = "10.16.101.0/24"
        ap-southeast-2b = "10.16.102.0/24"
    }
}

variable "private-subnets" {
    default = {
        ap-southeast-2a = "10.16.1.0/24"
        ap-southeast-2b = "10.16.2.0/24"
    }
}

variable "attach-subnets" {
    default = {
        ap-southeast-2a = "10.16.201.0/24"
        ap-southeast-2b = "10.16.202.0/24"
    }
}
