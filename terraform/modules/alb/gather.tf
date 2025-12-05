data "aws_subnet" "public-subnet1" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-subnet-1"]
  }
}

data "aws_subnet" "public-subnet2" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-subnet-2"]
  }
}

data "aws_security_group" "web-alb-sg" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-alb-sg"]
  }
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}
