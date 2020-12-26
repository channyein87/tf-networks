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
