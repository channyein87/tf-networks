variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "profile" {
  type    = string
  default = "kbshared"
}

variable "prefix" {
  type    = string
  default = "tf"
}

variable "environment" {
  type    = string
  default = "shared"
}

variable "onprem-ip" {
  type    = string
  default = "14.203.140.138"
}

variable "test-profile" {
  type    = string
  default = "kbtest"
}

variable "dev-profile" {
  type    = string
  default = "kbdev"
}

variable "prod-profile" {
  type    = string
  default = "kbprod"
}

variable "tunnel-1-cidr" {
  type    = string
  default = "169.254.10.0/30"
}

variable "tunnel-2-cidr" {
  type    = string
  default = "169.254.11.0/30"
}

variable "preshared-key" {
  type    = string
  default = "awsamazon"
}
