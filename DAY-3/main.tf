provider "aws" {
    region = "us-east-1"
}

module "ec2_instance" {
    source = "./modules/ec2_instance"
    ami_value = "ami-0354c98ae10b02961"
    instance_type_value = "t2.micro"
    subnet_id_value = "subnet-0d72644392afac8cf"
}
