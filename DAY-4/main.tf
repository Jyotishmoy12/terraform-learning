provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "ec2_instance" {
    instance_type = "t2.micro"
    ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
    subnet_id     = "subnet-0bb1c79de3EXAMPLE" # Replace with your subnet ID
}

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "my-unique-bucket-name-12345" # Replace with a unique bucket name
}

resource "aws_dynamodb_table" "terraform_lock" {
    name = "terraform-lock-table" 
    billing_mode = "PAY_PER_REQUEST" # Use on-demand billing mode
    hash_key = "LockID" # This is the primary key for the DynamoDB table

    attribute {
        name = "LockID" # this means the name of the attribute 
        type = "S"  # String
    }
}