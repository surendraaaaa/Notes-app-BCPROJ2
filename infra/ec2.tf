
# DATA SOURCE — UBUNTU 22.04 LTS AMI

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


# EC2 INSTANCES

# Bastion
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id
  key_name      = var.key_name
  security_groups = [aws_security_group.bastion_sg.id]
  tags = { Name = "bastion-host" }
}

# ssh -i MyAWSKP.pem ubuntu@<BastionPublicIP>
# create tunnel
# ssh -i MyAWSKP.pem -L 9000:10.0.11.10:9000 ubuntu@<BastionPublicIP>
# ssh -i MyAWSKP.pem -L 8081:10.0.12.10:8081 ubuntu@<BastionPublicIP>
# access on localhost
# http://localhost:9000   SonarQube
# http://localhost:8081   Nexus

# ssh -i MyAWSKP.pem ubuntu@10.0.11.10   # SonarQube
# ssh -i MyAWSKP.pem ubuntu@10.0.12.10   # Nexus
# ssh -i MyAWSKP.pem ubuntu@<EKS node private IP>
# From bastion host: configure kubectl using the cluster’s kubeconfig

# aws eks --region us-east-2 update-kubeconfig --name my-cluster
# kubectl get nodes

# from jenkins server for cicd
# example URL
# http://sonar-internal-alb-dns-name:9000
# http://nexus-internal-alb-dns-name:8081


# Jenkins
resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[1].id
  key_name      = var.key_name
  security_groups = [aws_security_group.jenkins_sg.id]
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y openjdk-17-jdk wget gnupg
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt update -y
    apt install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF
  tags = { Name = "jenkins-server" }
}

# SonarQube
resource "aws_instance" "sonarqube" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[0].id
  key_name      = var.key_name
  security_groups = [aws_security_group.internal_sg.id]
  iam_instance_profile = aws_iam_instance_profile.nexus_profile.name
  private_ip     = "10.0.11.10"
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    docker run -d --name sonarqube -p ${var.sonar_port}:9000 sonarqube:lts
  EOF
  tags = { Name = "sonarqube-server" }
}

# Nexus
resource "aws_instance" "nexus" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[1].id
  key_name      = var.key_name
  security_groups = [aws_security_group.internal_sg.id]
  iam_instance_profile = aws_iam_instance_profile.nexus_profile.name
  private_ip     = "10.0.12.10"
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    docker run -d --name nexus -p ${var.nexus_port}:8081 sonatype/nexus3
  EOF
  tags = { Name = "nexus-server" }
}


# IAM INSTANCE PROFILES

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_iam_instance_profile" "nexus_profile" {
  name = "nexus-instance-profile"
  role = aws_iam_role.nexus_role.name
}
