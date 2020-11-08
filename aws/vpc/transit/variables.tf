variable "region" {
    type = string
    default = "ap-southeast-2"
}

variable "profile" {
    type = string
    default = "cnnn"
}

variable "name" {
    type = string
    default = "tf-transit"
}

variable "environment" {
    type = string
    default = "transit"
}

variable "azs" {
    type = map(any)
    default = {
        ap-southeast-2 = ["ap-southeast-2a", "ap-southeast-2b"]
    }
}

variable "cidr" {
    type = string
    default = "10.100.0.0/16"
}

variable "private-subnets" {
    type = map(any)
    default = {
        ap-southeast-2 = ["10.100.1.0/24", "10.100.2.0/24"]
    }
}

variable "public-subnets" {
    type = map(any)
    default = {
        ap-southeast-2 = ["10.100.101.0/24", "10.100.102.0/24"]
    }
}
