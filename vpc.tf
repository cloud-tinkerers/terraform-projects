data "aws_availability_zones" "available" {}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  name               = "${var.project}"
  cidr               = "10.0.0.0/16"
  azs                = data.aws_availability_zones.available.names
  public_subnets     = ["10.0.1.0/24"]
  enable_nat_gateway = false
}