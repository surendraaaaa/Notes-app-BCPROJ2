##############################
# Variables
##############################
variable "env" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "allowed_ports" {
  description = "List of inbound ports to allow in the ECS security group"
  type        = list(number)
  default     = [80, 443, 8080, 3000, 5000]
}