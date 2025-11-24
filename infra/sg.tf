# SECURITY GROUPS

# Bastion
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { 
    from_port=0 
    to_port=0 
    protocol="-1" 
    cidr_blocks=["0.0.0.0/0"] 
    }
}

# Jenkins
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { 
    from_port=0 
    to_port=0 
    protocol="-1" 
    cidr_blocks=["0.0.0.0/0"] 
    }
}

resource "aws_security_group" "internal_sg" {
  name   = "internal-app-sg"
  vpc_id = aws_vpc.main.id
  description = "Internal SG for SonarQube & Nexus"

  # Allow traffic from Bastion + other members of this SG
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    self            = true   # allow traffic from other internal_sg members
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internal-app-sg"
  }
}
