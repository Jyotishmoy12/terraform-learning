terraform {
    backend "s3" {
        bucket = "my-terraform-state-bucket"
        key    = "terraform.tfstate"
        region = "us-east-1"
        encrypt = true # Enable server-side encryption
        dynamodb_table = "my-terraform-lock-table" # Optional: Use DynamoDB for state locking
    }
}