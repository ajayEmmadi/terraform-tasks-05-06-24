provider "aws" {
    region = "eu-west-2"
  
}

#creating an vpc
resource "aws_vpc" "ajayvpc" {
    cidr_block = "${var.vpc_cidr}"
    instance_tenancy = "default"
    tags = {
        Name = "New vpc"
    }
  
}

# creating an internet gateway
resource "aws_internet_gateway" "ajayigw" {
    vpc_id = "${aws_vpc.ajayvpc.id}"
}

#creating a route table
resource "aws_route_table" "route" {
    vpc_id ="${aws_vpc.ajayvpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.ajayigw.id}"
    }
    tags = {
        Name = "Route to internet"
    }

}
#creating a subnet
resource "aws_subnet" "public-subnet" {
    vpc_id = "${aws_vpc.ajayvpc.id}"
    cidr_block = "${var.subnet_cidr}"
    map_public_ip_on_launch = true
    availability_zone = "eu-west-2a"
    tags = {
        Name = "public-subnet"
    }
}

#associating route table to subnet
resource "aws_route_table_association" "public-subnet" {
    subnet_id = "${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.route.id}"

}

# Creating Security Group 
resource "aws_security_group" "security-sg" {
  vpc_id = "${aws_vpc.ajayvpc.id}"
# Inbound Rules
# HTTP access from anywhere
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# HTTPS access from anywhere
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# SSH access from anywhere
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# Outbound Rules
# Internet access to anywhere
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
tags = {
  Name = "Web SG"
}
}

#creating an network interface 
resource "aws_network_interface" "interface" {
  subnet_id       = aws_subnet.public-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.security-sg.id]

}

#assign an elastic ip to network interface
resource "aws_eip" "my_ip" {
 vpc = true

}
resource "aws_eip_association" "my_eip_association" {
  network_interface_id = aws_network_interface.interface.id
  allocation_id = aws_eip.my_ip.id

}

#creating an instance Ubuntu server and install/enable apache2

resource "aws_instance" "ubuntu_image" {
    ami = "ami-053a617c6207ecc7b"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public-subnet.id
    vpc_security_group_ids = [aws_security_group.security-sg.id]
    associate_public_ip_address = true  # Enable auto-assigning public IP
    user_data = <<-EOF
                 #!/bin/bash
                 apt-get update
                 apt-get install -y apache2
                 systemctl enable apache2
                 systemctl start apache2
                 EOF

                 tags = {
                   Name = "ubantu-instance"
                 }
}

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "s3bucket890123"
    acl = "private"
    
}

#Create dynamo db using terraform:
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-state-lock-dynamoajay"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}

#S3 as backend for terraform.tfstate file:

terraform {
  backend "s3" {
    bucket = "s3bucket890123"
    dynamodb_table = "terraform-state-lock-dynamoajay"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}

















