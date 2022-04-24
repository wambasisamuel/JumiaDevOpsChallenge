terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}
