# Terraform Conditional Expressions

Conditional expressions in Terraform allow you to choose one value or another
based on a condition.

## Syntax

```hcl
condition ? true_value : false_value
```

If the condition is `true`, Terraform uses `true_value`. If the condition is
`false`, Terraform uses `false_value`.

## Conditional Resource Creation

You can use a conditional expression with `count` to decide whether a resource
should be created.

```hcl
variable "create_instance" {
  description = "Whether to create an EC2 instance"
  type        = bool
  default     = true
}

resource "aws_instance" "example" {
  count = var.create_instance ? 1 : 0

  ami           = "ami-0123456789abcdef0"
  instance_type = "t2.micro"
}
```

In this example:

1. If `create_instance` is `true`, Terraform creates one EC2 instance.
2. If `create_instance` is `false`, Terraform creates zero EC2 instances.

## Conditional Variable Assignment

You can use a conditional expression to choose a value based on the environment.

```hcl
variable "environment" {
  description = "Environment type"
  type        = string
  default     = "development"
}

variable "production_subnet_cidr" {
  description = "CIDR block for production subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "development_subnet_cidr" {
  description = "CIDR block for development subnet"
  type        = string
  default     = "10.0.2.0/24"
}

locals {
  subnet_cidr = var.environment == "production" ? var.production_subnet_cidr : var.development_subnet_cidr
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.subnet_cidr]
  }
}
```

In this example:

1. If `environment` is set to `production`, Terraform uses
   `production_subnet_cidr`.
2. For any other value, Terraform uses `development_subnet_cidr`.
3. The selected value is stored in `local.subnet_cidr`.

## Conditional Resource Configuration

You can also use a conditional expression to control part of a resource
configuration.

```hcl
variable "enable_ssh" {
  description = "Whether to allow SSH access"
  type        = bool
  default     = false
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.enable_ssh ? ["0.0.0.0/0"] : []
  }
}
```

In this example:

1. If `enable_ssh` is `true`, SSH access is allowed from `0.0.0.0/0`.
2. If `enable_ssh` is `false`, no CIDR blocks are added for SSH access.
