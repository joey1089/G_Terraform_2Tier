#---  root/locals.tf ---

# local cidr block value for VPC
locals {
  vpc_cidr = "10.12.0.0/16"
}

locals {
  security_groups = {
    public = {
      name        = "my_public_sg"
      description = "Security Group for public Access"
      ingress = {
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    rds = {
      name        = "rds_sub_grp"
      description = "RDS Access for private subnet"
      ingress = {
        mysql = {
          from        = 3306
          to          = 3306
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidr]
        }
      }
    }
  }
}

