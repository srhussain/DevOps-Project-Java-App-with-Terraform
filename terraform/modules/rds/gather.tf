data "aws_subnet" "private-subnet-1" {
filter {
  name = "tag:Name"
  values = ["${var.environment}-private-subnet-1"]
}  
}

data "aws_subnet" "private-subnet-2" {
filter {
  name = "tag:Name"
  values = ["${var.environment}-private-subnet-2"]
}  
}


data "aws_security_group" "db-sg" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-db-sg"]
  }
}