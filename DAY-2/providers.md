# Terraform Providers

A provider in Terraform is a plugin that enables Terraform to interact with an API.

For example, the AWS provider allows Terraform to create and manage AWS resources.

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0123456789abcdef0" # Change the AMI
  instance_type = "t2.micro"
}
```

## Examples of Other Providers

Some commonly used Terraform providers are:

1. `azurerm` - for Microsoft Azure
2. `google` - for Google Cloud Platform
3. `kubernetes` - for Kubernetes
4. `openstack` - for OpenStack

## Different Ways to Configure Providers in Terraform

Terraform providers can be configured in multiple ways depending on how your
infrastructure code is organized.

### Configure Providers in a Child Module

You can configure providers in a child module. This is useful when you want to
reuse the same provider configuration across multiple resources or modules.

```hcl
module "aws_vpc" {
  source = "./aws_vpc"

  providers = {
    aws = aws.us-west-2
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"

  depends_on = [module.aws_vpc]
}
```

### Configure Providers in the `required_providers` Block

You can also configure providers in the `required_providers` block. This is
useful when you want to make sure that a specific provider source and version
are used.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.79"
    }
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"
}
```
