variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "OXO-dev"
}

variable "ami" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "ami-02b8269d5e85954ef"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "vpc_cidr_bastion" {
  description = "CIDR block for Bastion VPC"
  type        = string
  default     = "172.32.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24"]
}

variable "public_subnets_bastion" {
  description = "CIDR blocks for Bastion public subnets"
  type        = list(string)
  default     = ["172.32.1.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["192.168.3.0/24", "192.168.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "javaapp"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  # sensitive   = true
  default = "devops"
}

variable "db_password" {
  description = "Enter MySQL root password"
  type        = string
  sensitive   = true
}


variable "sg-name" {
  description = "Database master password"
  type        = string
  default     = "oxigon"
}

variable "alb-name" {
  description = "Database master password"
  type        = string
  default     = "Oxigon-ALB"
}

variable "tg-name" {
  description = "Database master password"
  type        = string
  default     = "Oxigon-APP-TG"
}

variable "bastion_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "iam-role" {
  description = "EC2 instance type"
  type        = string
  default     = "EC2-role"
}

variable "iam-policy" {
  description = "EC2 instance type"
  type        = string
  default     = "EC2-Policy"
}

variable "instance-profile-name" {
  description = "EC2 instance type"
  type        = string
  default     = "EC2-Role-instance-profile"
}

# variable "key_name" {
#   description = "Name of the SSH key pair"
#   type        = string
# }

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}
