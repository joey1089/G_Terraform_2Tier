# ----root/main.tf ---

# local cidr block value for VPC
locals {
  vpc_cidr = "10.11.0.0/16"
}

module "networking" {
  source   = "./networking"
  vpc_cidr = local.vpc_cidr
  #add - access_ip for the public security group
  access_ip = var.access_ip
  # public_cidrs  = ["10.10.2.0/24", "10.10.4.0/24"] 
  # put in for loop and in range give subnet range
  # private_cidrs = ["10.10.1.0/24", "10.10.3.0/24"]
  private_sn_count = 3
  #length(public_cidrs) - doesn'twork
  public_sn_count = 2
  max_subnets     = 20
  public_cidrs    = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs   = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  # private_cidrs = [for i in range(1,255,2) : cidrsubnet("10.10.0.0/16", 8, i)]
}

