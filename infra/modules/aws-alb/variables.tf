variable "env" {
  description = "Environment name"
  type        = string
}

variable "name" {
  description = "Application name, e.g. platform"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}

variable "alb_sg" {
  description = "Security group attached to ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate for HTTPS"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "deletion_protection" {
  type    = bool
  default = false
}

#############################
# Dynamic target groups
#############################
variable "target_groups" {
  description = "Map of target groups for services"
  type = map(object({
    port               = number
    priority           = number
    path_patterns      = list(string)
    health_check_path  = string
  }))
}
