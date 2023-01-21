# --- root/main.tf ---
#Deploy Networking Resources

module "resources_network" {
  source        = "./network_resources"
  vpc_cidr      = "10.10.0.0/16"
  private_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
  rds_private_cidrs = ["10.10.3.0/24","10.10.4.0/24"]
  public_cidrs  = ["10.10.5.0/24", "10.10.6.0/24"]
}