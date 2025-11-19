variable "env" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Name of the ECS service (frontend/backend)"
  type        = string
}

variable "image" {
  description = "Docker image for the ECS task"
  type        = string
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "port" {
  description = "Container port"
  type        = number
}

variable "replicas" {
  description = "Desired count of ECS tasks"
  type        = number
  default     = 1
}

variable "subnets" {
  description = "List of subnet IDs from network module"
  type        = list(string)
}

variable "primary_sg" {
  description = "Primary security group from aws-network module"
  type        = string
}

variable "extra_sgs" {
  description = "Optional additional SGs to attach"
  type        = list(string)
  default     = []
}

variable "target_group_arn" {
  description = "Load balancer target group ARN"
  type        = string
}
