resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app" {
  key_name   = "${var.environment}-app-key"
  public_key = tls_private_key.app_key.public_key_openssh
}

# Save the private key locally (only once)
resource "local_file" "app_key_file" {
  content         = tls_private_key.app_key.private_key_pem
  filename        = "${path.module}/${var.environment}-app-key.pem"
  file_permission = "0400"
}
