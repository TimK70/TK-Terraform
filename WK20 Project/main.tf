#Providers section:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  
}

resource "aws_instance" "my-webserver" {
  ami = ""
  instance_type = ""
  security_groups = 
  
}


# resource "aws_ec2_availability_zone_group" "wk20projecta" {
#   group_name    = "us-east-1a"
#   opt_in_status = "opted-in"
# }

# resource "aws_ec2_availability_zone_group" "wk20projectb" {
#   group_name    = "us-east-1b"
#   opt_in_status = "opted-in"
# }

# resource "aws_ec2_availability_zone_group" "wk20projectc" {
#   group_name    = "us-east-1c"
#   opt_in_status = "opted-in"
# }


# variable "security_group_id" {}

# data "aws_security_group" "selected" {
#   id = var.security_group_id
# }

# resource "aws_subnet" "subnet" {
#   vpc_id     = data.aws_security_group.selected.vpc_id
#   cidr_block = "10.0.1.0/24"
# }