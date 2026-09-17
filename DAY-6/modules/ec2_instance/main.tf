provider "aws" {
  region = "us-east-1"
}

variable "ami" {
  description = "The AMI ID to use for the EC2 instance"
}

variable "instance_type" {
  description = "The type of instance to create"
  default     = "t2.micro"
}

resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
}