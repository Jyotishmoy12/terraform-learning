
# get the variable from variables.tf file
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}


# create a subnet inside the VPC 
# map public ip on launch is set to true so that the ec2 instance created inside this subnet will have a public ip address.
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


# create an internet gateway and attach it to the VPC
# internet gateway is used to allow the resources inside the VPC to access the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}


# create a route table and associate it with the subnet
# route table is used to define the routes for the resources inside the VPC.
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  # create a route to allow the resources inside the VPC to access the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# associate the route table with the subnet
# this is required to allow the resources inside the subnet to access the internet.
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}


# create a security group inside the VPC
# security group is used to define the inbound and outbound rules for the resources inside the VPC. in easy words, it is a virtual firewall that controls the traffic to and from the resources inside the VPC.
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id
  # ingress means inbound rules. here we are allowing the inbound traffic on port 80 from any ip address.
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # here we are allowing the inbound traffic on port 22 from any ip address. this is required to ssh into the ec2 instance created inside the VPC.
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress means outbound rules. here we are allowing the outbound traffic on all ports to any ip address.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols. this is required to allow the resources inside the VPC to access the internet.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tags are used to identify the resources inside the VPC. here we are giving the name "web" to the security group.
  tags = {
    Name = "web"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "jyoti-vpc-ec2-demo-20260915"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "webserver1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = file("userdata.sh") # This script will run when the instance is launched
}

resource "aws_instance" "webserver2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = file("userdata.sh")
}


# create an application load balancer
# load balancer is used to distribute the incoming traffic to the resources inside the VPC. in this case, it will distribute the traffic to the two ec2 instances created above.
resource "aws_lb" "myalb" {
  name               = "my-alb"
  internal           = false # internal means the load balancer will be accessible from the internet. if it is set to true, then the load balancer will be accessible only from the resources inside the VPC.
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "web"
  }
}


# create a target group for the load balancer
# target group is used to define the targets (ec2 instances) for the load balancer. in this case, it will define the two ec2 instances created above as targets for the load balancer.
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

# attach the target group to the load balancer
# this is required to allow the load balancer to distribute the incoming traffic to the targets defined in the target group.
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}


# create a listener for the load balancer
# listener is used to define the protocol and port for the load balancer. in this case, it will define the protocol as HTTP and the port as 80. it will also define the default action for the listener, which is to forward the incoming traffic to the target group defined above.
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "loadbalancer_dns_name" {
  value = aws_lb.myalb.dns_name
}
