variable "env" { type = string }
variable "location" { type = string }
variable "name" { type = string }
variable "image" { type = string }
variable "cpu" { type = number, default = 0.5 }
variable "memory" { type = number, default = 1 }
variable "port" { type = number }

variable "vnet_cidr" { type = string }
variable "subnet_cidr" { type = string }
variable "internal_lb" { type = bool, default = false }
variable "external_ingress" { type = bool, default = true }

variable "environment_variables" { type = map(string), default = {} }

variable "docker_registry_server" { type = string }
variable "docker_registry_username" { type = string }
variable "docker_registry_password" { type = string, sensitive = true }

variable "min_replicas" { type = number, default = 1 }
variable "max_replicas" { type = number, default = 3 }
variable "resource_group_name" { type = string }
