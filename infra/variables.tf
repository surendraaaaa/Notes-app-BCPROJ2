
# VARIABLES (multi-environment ready)

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "azs" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b"]
}

variable "key_name" {
  type    = string
  default = "MyAWSKP"
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "jenkins_port" {
  type    = number
  default = 8080
}

variable "sonar_port" {
  type    = number
  default = 9000
}

variable "nexus_port" {
  type    = number
  default = 8081
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "MyAWSKP"
}

