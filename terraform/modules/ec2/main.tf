resource "aws_instance" "example" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [data.aws_security_group.app-sg.id]
  iam_instance_profile   = var.instance-profile-name
  key_name               = aws_key_pair.app.key_name

  tags = {
    Name = "${var.environment}-ec2-medium"
  }
}
