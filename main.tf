# -------- Data lookups (default VPC + subnet + AMI) --------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------- SSH Key Pair --------
resource "aws_key_pair" "deployment_key" {
  key_name   = "deployment-test-key"
  public_key = var.public_key  # Use variable instead of hardcoded key
}

# -------- Security Group (SSH + HTTP + HTTPS) --------
resource "aws_security_group" "web_sg" {
  name        = "deployment-test-web-sg-v2"
  description = "Allow HTTP, HTTPS, and SSH for web application"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "deployment-test-web-sg-v2"
  }
}

# -------- EC2 Instance --------
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = "t2.micro"
  availability_zone           = "us-east-2a"
  subnet_id                   = data.aws_subnets.default_vpc_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = aws_key_pair.deployment_key.key_name
  associate_public_ip_address = true

  # Install Docker and run your application
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Install Git
              yum install -y git
              
              echo "Web server is ready for deployment!" > /etc/motd
              EOF

  tags = {
    Name = "deployment-test-web-server"
  }
}

# -------- Outputs --------
output "instance_id" {
  value       = aws_instance.web_server.id
  description = "EC2 instance ID"
}

output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP of the instance"
}

output "public_dns" {
  value       = aws_instance.web_server.public_dns
  description = "Public DNS of the instance"
}

output "ssh_command" {
  value       = "ssh -i your-key.pem ec2-user@${aws_instance.web_server.public_ip}"
  description = "SSH command to connect to the instance"
}