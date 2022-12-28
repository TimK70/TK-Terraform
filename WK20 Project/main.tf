# ------/root/main.tf-----------------

#1-Providers section:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}
#2-This will be our default region. If you're using an IDE other than Cloud9, you will
# put your access_key and secret_key here, below region =.
provider "aws" {
  region = "us-east-2"
}

# resource "aws_key_pair" "wk20kp" {
#   key_name = "wk20kp"
#   public_key = ""
# }
#3-VPC info --- using the default vpc.
resource "aws_default_vpc" "defaultvpc" {
  tags = {
    Name = "defaultvpc"
  }
}

#Internet Gateway (IG) which will allow us to reach the internet and will be attached to public RT 
resource "aws_internet_gateway" "project_gw" {
  vpc_id = aws_default_vpc.defaultvpc.id #Refers to our default vpc
  tags = {
    Name = "Project gw"
  }
}
#Setting up three Public Subnets:
resource "aws_subnet" "public_subnet1a" {
  vpc_id                  = aws_default_vpc.defaultvpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet for us-east-1a"
  }
}
resource "aws_subnet" "public_subnet1b" {
  vpc_id                  = aws_default_vpc.defaultvpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet for us-east-1b"
  }
}
resource "aws_subnet" "public_subnet1c" {
  vpc_id                  = aws_default_vpc.defaultvpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet for us-east-1c"
  }
}
#And three Private Subnets
resource "aws_subnet" "private_subnet1a" {
  vpc_id            = aws_default_vpc.defaultvpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.4.0/24"
  tags = {
    Name = "Private subnet for us-east-1a"
  }
}
resource "aws_subnet" "private_subnet1b" {
  vpc_id            = aws_default_vpc.defaultvpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.5.0/24"
  tags = {
    Name = "Private subnet for us-east-1b"
  }
}
resource "aws_subnet" "private_subnet1c" {
  vpc_id            = aws_default_vpc.defaultvpc.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.6.0/24"
  tags = {
    Name = "Private subnet for us-east-1c"
  }
}
#Listing the default route table, so it won't have any associations
resource "aws_default_route_table" "mainRT" {
  default_route_table_id = aws_default_vpc.defaultvpc.default_route_table_id
}
#public Route Table to go with the public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_default_vpc.defaultvpc.id

  route {
    cidr_block = "0.0.0.0/0" #Need it to be this so we can reach the Internet
    gateway_id = aws_internet_gateway.project_gw.id
  }
  tags = {
    Name = "Second Route Table"
  }
}
#Here, we will pair up our Public Rout Table to our Public Subnets
resource "aws_route_table_association" "public_route1a" {
  subnet_id      = aws_subnet.public_subnet1a.id
  route_table_id = aws_route_table.public_rt
}
resource "aws_route_table_association" "public_route1b" {
  subnet_id      = aws_subnet.public_subnet1b.id
  route_table_id = aws_route_table.public_rt
}
resource "aws_route_table_association" "public_route1c" {
  subnet_id      = aws_subnet.public_subnet1c.id
  route_table_id = aws_route_table.public_rt
}

#Next, we'll make a RT for the Private Subnets:
resource "aws_route_table" "private_rt" {
  vpc_id = aws_default_vpc.defaultvpc.id

  tags = {
    Name = "private_rt"
  }
}
#Next, we will pair our private subnets to the Private RT:
resource "aws_route_table_association" "private_route1a" {
  subnet_id      = aws_subnet.public_subnet1a.id
  route_table_id = aws_route_table.private_rt
}
resource "aws_route_table_association" "private_route1b" {
  subnet_id      = aws_subnet.public_subnet1b.id
  route_table_id = aws_route_table.private_rt
}
resource "aws_route_table_association" "private_route1c" {
  subnet_id      = aws_subnet.public_subnet1c.id
  route_table_id = aws_route_table.private_rt
}

#7-Security group that will allow all traffic to webservers on port 80 & ssh from our IP:
resource "aws_security_group" "HTTP_sg" {
  name        = "HTTP_sg"
  description = "Enable HTTP access to ec2 instances"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer--Internet facing
# resource "aws_alb" "alb" {
#   name               = "alb"
#   load_balancer_type = "application"
#   internal           = false
#   subnets            = [aws_subnet.public_subnet1a.id, aws_subnet.public_subnet1b.id, aws_subnet.public_subnet1c.id]
#   security_groups    = [aws_security_group.default.id]


# }
# Finally, we'll provision 3 EC2 instances, each in a different AZ.
resource "aws_instance" "my-webserver1" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet1a.id
  security_groups = [aws_security_group.HTTP_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF

}
resource "aws_instance" "my-webserver2" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet1b.id
  security_groups = [aws_security_group.HTTP_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}
resource "aws_instance" "my-webserver3" {
  ami             = "ami-09fe851c8e75cbbf8"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_subnet1c.id
  security_groups = [aws_security_group.HTTP_sg.id]

  user_data = <<-EOF
    "#!/bin/bash
    yum -y update
    yum -y install nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h2>My NGINX Webserver</h2><br>Built by Terraform" > /var/www/html/index.html"
    EOF
}


