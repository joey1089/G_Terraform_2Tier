# ----root/main.tf ---

module "networking" {
  source   = "./networking"
  vpc_cidr = "10.10.0.0/16"
}