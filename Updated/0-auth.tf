
# https://registry.terraform.io/providers/hashicorp/aws/6.17.0/docs/resources/subnet

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.8.0"
    }



  }
}
