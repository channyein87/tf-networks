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

variable "onprem-dns-name" {
  type    = string
  default = "contoso.local"
}

variable "onprem-dns-ips" {
  type    = list(string)
  default = ["192.168.11.211", "192.168.21.211"]
}
