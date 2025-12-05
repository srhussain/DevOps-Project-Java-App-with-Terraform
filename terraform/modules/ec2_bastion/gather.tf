data "aws_security_group" "bastion-sg" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-bastion-sg"]
  }
}