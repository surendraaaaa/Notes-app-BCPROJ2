variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type = string
}

variable "frontend_image" {
  type = string
}

variable "backend_image" {
  type = string
}

variable "vnet_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "frontend_subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "backend_subnet_cidr" {
  type    = string
  default = "10.20.2.0/24"
}

variable "backend_subnet_id" {
  type = string
}

variable "registry_server" {
  type = string
}

variable "registry_username" {
  type = string
}

variable "registry_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "notes_db"
}

variable "db_username" {
  type    = string
  default = "root"
}

variable "db_password" {
  type      = string
  sensitive = true
}
