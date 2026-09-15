variable "cidr" {
  default = "10.0.0.0/16" # This ip address range is used to create the VPC which means
  # all the resources created inside this VPC will have ip addresses from this range.
}