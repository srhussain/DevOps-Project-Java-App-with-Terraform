resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${var.environment}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# Save the private key locally (only once)
resource "local_file" "bastion_key_file" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "${path.module}/${var.environment}-bastion-key.pem"
  file_permission = "0400"
}