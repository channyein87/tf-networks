provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "aws" {
  region  = var.region
  profile = var.test-profile
  alias   = "test"
}

provider "aws" {
  region  = var.region
  profile = var.dev-profile
  alias   = "dev"
}

provider "aws" {
  region  = var.region
  profile = var.prod-profile
  alias   = "prod"
}
