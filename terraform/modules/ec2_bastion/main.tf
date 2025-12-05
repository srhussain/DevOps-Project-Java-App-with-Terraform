resource "aws_instance" "example" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  vpc_security_group_ids = [data.aws_security_group.bastion-sg.id]
  key_name                    = aws_key_pair.bastion.key_name
#   iam_instance_profile= var.instance-profile-name

  tags = {
    Name = "${var.environment}-ec2-medium-bastion"
  }
}