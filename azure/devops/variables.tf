variable "prefix" {
  type    = string
  default = "chko-azdevops"
}

variable "location" {
  type    = string
  default = "Australia East"
}

variable "vnet-cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet-cidr" {
  type    = list(string)
  default = ["10.20.0.0/20", "10.20.16.0/20"]
}

variable "subnet-name" {
  type    = list(string)
  default = ["private-subnet", "public-subnet"]
}

variable "container-cidr" {
  type    = list(string)
  default = ["10.20.32.0/20"]
}

variable "agent-image" {
  type    = string
  default = "channyein87/azdevopsagent:2"
}
