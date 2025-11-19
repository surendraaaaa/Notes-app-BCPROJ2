variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS"
  type        = string
}

variable "frontend_image" {
  description = "Docker image for frontend ECS service"
  type        = string
}

variable "backend_image" {
  description = "Docker image for backend ECS service"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "notes_db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "root"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
