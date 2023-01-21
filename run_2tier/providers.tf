# --- root/providers.tf ---


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.region
}