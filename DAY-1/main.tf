provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "example"{
    ami  = "ami-0354c98ae10b02961"  # ami id means: Amazon Machine Image ID, which is a template that contains a software configuration (operating system, application server, and applications) used to launch an instance.
    instance_type = "t2.micro"
}