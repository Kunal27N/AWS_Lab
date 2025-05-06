
# Generate the private key
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create the SSH Key Pair in AWS
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-terraform-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "aws_security_group" "my_security_group" {
  name        = "my-ec2-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.vpc_id  # Specify the VPC ID for the security group

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "my_ec2" {
  ami                         = var.ami_id # Amazon Linux 2 in us-east-1
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id            # Subnet in your existing VPC
  key_name                    = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.my_security_group.id]

  tags = {
    Name = "MyEC2"
  }
}

# Save the private key to a local file (downloaded on your machine)
resource "local_file" "private_key" {
  filename = "${path.module}/my-terraform-key.pem"
  content  = tls_private_key.my_key.private_key_pem
  file_permission = "0400"
}
