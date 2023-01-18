terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  # aws_access_key_id     = var.aws_access_key_id
  # aws_secret_access_key = var.aws_secret_access_key
  # access_key = var.aws_access_key_id
  # secret_key = var.aws_secret_access_key
}



