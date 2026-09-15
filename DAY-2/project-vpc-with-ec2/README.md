# VPC with EC2 and Application Load Balancer

This Terraform project creates a small public web application on AWS. It builds
a VPC, two public subnets, two EC2 web servers, a security group, an Application
Load Balancer, a target group, and an S3 bucket.

## Architecture Flow

```text
Internet
   |
   v
Application Load Balancer
   |
   v
Target Group
   |
   +-------------------+
   |                   |
   v                   v
EC2 webserver1     EC2 webserver2
subnet1            subnet2
us-east-1a         us-east-1b
   \                   /
    \                 /
        VPC: 10.0.0.0/16
```

## How the Pieces Connect

1. The VPC creates an isolated network in AWS.
2. Two public subnets are created inside the VPC in different availability zones.
3. An Internet Gateway is attached to the VPC so public resources can access the internet.
4. A route table sends internet traffic through the Internet Gateway.
5. Both subnets are associated with the route table, making them public subnets.
6. A security group allows HTTP traffic on port `80` and SSH traffic on port `22`.
7. Two EC2 instances are launched, one in each subnet.
8. `userdata.sh` installs Apache and creates an HTML page on each EC2 instance.
9. The Application Load Balancer receives public traffic from the internet.
10. The target group connects the load balancer to the EC2 instances.
11. The listener listens on HTTP port `80` and forwards traffic to the target group.
12. Terraform outputs the load balancer DNS name so you can open the app in a browser.

## Files

| File | Purpose |
| --- | --- |
| `provider.tf` | Defines the AWS provider and region. |
| `variables.tf` | Defines input variables used by the project. |
| `main.tf` | Creates the AWS networking, EC2, load balancer, and S3 resources. |
| `userdata.sh` | Runs on EC2 instance startup to install Apache and create the HTML page. |

## Provider Configuration

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

| Property | Explanation |
| --- | --- |
| `required_providers` | Tells Terraform which provider plugins this project needs. |
| `aws` | The provider name used to create AWS resources. |
| `source` | The provider source address from the Terraform Registry. |
| `version` | The AWS provider version Terraform should use. |
| `region` | The AWS region where resources will be created. |

## Variable

```hcl
variable "cidr" {
  default = "10.0.0.0/16"
}
```

| Property | Explanation |
| --- | --- |
| `variable "cidr"` | Declares an input variable named `cidr`. |
| `default` | Provides the VPC CIDR range if no custom value is passed. |

## VPC

```hcl
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}
```

| Property | Explanation |
| --- | --- |
| `aws_vpc` | Creates a Virtual Private Cloud in AWS. |
| `myvpc` | Terraform's local name for this VPC resource. |
| `cidr_block` | Defines the IP address range for the VPC. |
| `var.cidr` | Uses the value from the `cidr` variable. |

## Subnets

```hcl
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
```

| Property | Explanation |
| --- | --- |
| `aws_subnet` | Creates a subnet inside the VPC. |
| `vpc_id` | Connects the subnet to `aws_vpc.myvpc`. |
| `cidr_block` | Defines the smaller IP range for each subnet. |
| `availability_zone` | Places each subnet in a specific AWS availability zone. |
| `map_public_ip_on_launch` | Gives launched EC2 instances a public IP automatically. |

## Internet Gateway

```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}
```

| Property | Explanation |
| --- | --- |
| `aws_internet_gateway` | Creates an internet gateway for internet access. |
| `vpc_id` | Attaches the internet gateway to the VPC. |

## Route Table

```hcl
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
```

| Property | Explanation |
| --- | --- |
| `aws_route_table` | Creates routing rules for traffic inside the VPC. |
| `vpc_id` | Connects the route table to the VPC. |
| `route` | Defines where matching traffic should go. |
| `cidr_block = "0.0.0.0/0"` | Matches all IPv4 internet traffic. |
| `gateway_id` | Sends internet traffic to the Internet Gateway. |

## Route Table Associations

```hcl
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}
```

| Property | Explanation |
| --- | --- |
| `aws_route_table_association` | Connects a subnet to a route table. |
| `subnet_id` | Selects which subnet should use the route table. |
| `route_table_id` | Selects the route table used by the subnet. |

## Security Group

```hcl
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
```

| Property | Explanation |
| --- | --- |
| `aws_security_group` | Creates firewall rules for resources in the VPC. |
| `name` | Sets the security group name in AWS. |
| `vpc_id` | Creates the security group inside the VPC. |
| `ingress` | Defines inbound traffic rules. |
| `from_port` / `to_port` | Defines the allowed port range. |
| `protocol` | Defines the network protocol, such as `tcp`. |
| `cidr_blocks` | Defines which IP ranges can access the rule. |
| `egress` | Defines outbound traffic rules. |
| `protocol = "-1"` | Allows all protocols for outbound traffic. |

## S3 Bucket

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "jyoti-vpc-ec2-demo-20260915"
}
```

| Property | Explanation |
| --- | --- |
| `aws_s3_bucket` | Creates an S3 bucket. |
| `bucket` | Sets the globally unique S3 bucket name. |

## Ubuntu AMI Lookup

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

| Property | Explanation |
| --- | --- |
| `data "aws_ami"` | Looks up an existing AMI instead of creating one. |
| `most_recent` | Picks the latest matching AMI. |
| `owners` | Restricts the AMI owner to Canonical, the Ubuntu publisher. |
| `filter` | Narrows the AMI search using specific conditions. |
| `name` | Tells AWS which AMI attribute to filter on. |
| `values` | Defines the AMI name pattern to match. |

## EC2 Instances

```hcl
resource "aws_instance" "webserver1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = file("userdata.sh")
}
```

| Property | Explanation |
| --- | --- |
| `aws_instance` | Creates an EC2 instance. |
| `ami` | Selects the operating system image for the instance. |
| `instance_type` | Selects the instance size and capacity. |
| `vpc_security_group_ids` | Attaches the web security group to the instance. |
| `subnet_id` | Places the instance inside a specific subnet. |
| `user_data` | Runs a startup script when the instance launches. |

## User Data Script

```bash
apt update
apt install -y apache2
cat <<EOF > /var/www/html/index.html
...
EOF
systemctl start apache2
systemctl enable apache2
```

| Command | Explanation |
| --- | --- |
| `apt update` | Refreshes Ubuntu package information. |
| `apt install -y apache2` | Installs the Apache web server. |
| `curl ... instance-id` | Reads the EC2 instance ID from instance metadata. |
| `cat <<EOF > /var/www/html/index.html` | Creates the HTML page served by Apache. |
| `systemctl start apache2` | Starts the Apache service. |
| `systemctl enable apache2` | Makes Apache start automatically after reboot. |

## Application Load Balancer

```hcl
resource "aws_lb" "myalb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webSg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}
```

| Property | Explanation |
| --- | --- |
| `aws_lb` | Creates a load balancer. |
| `name` | Sets the load balancer name. |
| `internal = false` | Makes the load balancer internet-facing. |
| `load_balancer_type` | Creates an Application Load Balancer. |
| `security_groups` | Controls traffic allowed to the load balancer. |
| `subnets` | Places the load balancer across both public subnets. |

## Target Group

```hcl
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}
```

| Property | Explanation |
| --- | --- |
| `aws_lb_target_group` | Defines where the load balancer sends traffic. |
| `name` | Sets the target group name. |
| `port` | Defines the port targets receive traffic on. |
| `protocol` | Defines the protocol used to reach targets. |
| `vpc_id` | Places the target group inside the VPC. |
| `health_check` | Defines how AWS checks whether targets are healthy. |
| `path = "/"` | Checks the homepage path on each instance. |
| `port = "traffic-port"` | Uses the same port as the target group. |

## Target Group Attachments

```hcl
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}
```

| Property | Explanation |
| --- | --- |
| `aws_lb_target_group_attachment` | Registers an EC2 instance with the target group. |
| `target_group_arn` | Selects the target group to attach to. |
| `target_id` | Selects the EC2 instance that receives traffic. |
| `port` | Defines the port used by the target instance. |

## Listener

```hcl
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
```

| Property | Explanation |
| --- | --- |
| `aws_lb_listener` | Listens for incoming requests on the load balancer. |
| `load_balancer_arn` | Connects the listener to the load balancer. |
| `port` | Defines the public port users connect to. |
| `protocol` | Defines the listener protocol. |
| `default_action` | Defines what happens to matching traffic. |
| `type = "forward"` | Sends traffic to a target group. |
| `target_group_arn` | Selects the target group that receives traffic. |

## Output

```hcl
output "loadbalancer_dns_name" {
  value = aws_lb.myalb.dns_name
}
```

| Property | Explanation |
| --- | --- |
| `output` | Prints useful information after `terraform apply`. |
| `value` | Selects the value to print. |
| `aws_lb.myalb.dns_name` | Returns the public DNS name of the load balancer. |

## Commands

Run these commands from this project folder:

```powershell
cd C:\dev\terraform-learning\DAY-2\project-vpc-with-ec2
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After testing, destroy the resources to avoid AWS charges:

```powershell
terraform destroy
```

## AWS Console Checks

After applying, check these services in the `us-east-1` region:

1. **VPC**: Confirm a VPC exists with CIDR `10.0.0.0/16`.
2. **Subnets**: Confirm two subnets exist in `us-east-1a` and `us-east-1b`.
3. **Internet Gateway**: Confirm it is attached to the VPC.
4. **Route Table**: Confirm `0.0.0.0/0` routes to the Internet Gateway.
5. **Security Group**: Confirm inbound HTTP `80` and SSH `22` are allowed.
6. **EC2 Instances**: Confirm both instances are running and have public IPs.
7. **Target Group**: Confirm both EC2 targets become healthy.
8. **Load Balancer**: Open the ALB DNS name in a browser.
9. **S3**: Confirm the bucket exists.

## Troubleshooting

If the EC2 public IP says `connection refused`, Apache may not be running or
user data may not have completed.

Connect to the instance and check:

```bash
sudo systemctl status apache2
sudo cat /var/log/cloud-init-output.log
sudo cat /var/www/html/index.html
```

If you changed `userdata.sh` after creating the instance, recreate the
instances so user data runs again:

```powershell
terraform apply -replace="aws_instance.webserver1" -replace="aws_instance.webserver2"
```
