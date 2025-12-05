resource "aws_instance" "example" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [data.aws_security_group.app-sg.id]
  iam_instance_profile   = var.instance-profile-name
  key_name               = aws_key_pair.app.key_name

  user_data = file("${path.module}/scripts/install_app.sh")

  tags = {
    Name = "${var.environment}-ec2-medium"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/dev/myapp/db_username"
  type  = "String"
  value = var.db_username
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/dev/myapp/db_password"
  type  = "SecureString"
  value = var.db_password
}




