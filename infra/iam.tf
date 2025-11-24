# IAM ROLES

# Jenkins role
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Attach EKS Cluster permissions to Jenkins role
resource "aws_iam_role_policy_attachment" "jenkins_eks_cluster" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach EKS Worker Node permissions to Jenkins role (if Jenkins needs to manage nodes)
resource "aws_iam_role_policy_attachment" "jenkins_eks_worker" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Optional: Pull images from ECR
resource "aws_iam_role_policy_attachment" "jenkins_ecr_read" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Nexus S3 backup role
resource "aws_iam_role" "nexus_role" {
  name = "nexus-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nexus_s3" {
  role       = aws_iam_role.nexus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}