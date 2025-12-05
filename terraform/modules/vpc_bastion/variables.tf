variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr_bastion" {
  description = "CIDR block for VPC"
  type        = string
}

# variable "public_subnets" {
#   description = "List of public subnet CIDR blocks"
#   type        = list(string)
# }

variable "public_subnets_bastion" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default = []
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
} 