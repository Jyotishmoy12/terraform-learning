

variable "instance_type" {
  description = "EC2 instance type"
  type = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type = string
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "example_instance" {
    ami          = var.ami_id
    instance_type = var.instance_type
}

output "public_ip" {
    description = "The public IP address of the EC2 instance"
    value       = aws_instance.example_instance.public_ip
}