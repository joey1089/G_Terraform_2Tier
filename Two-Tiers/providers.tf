# --- root/providers.tf --- 
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
#   region = "us-west-2"
    region = var.aws_region
}