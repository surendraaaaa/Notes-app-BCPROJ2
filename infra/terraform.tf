terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.16.0"
    }
  }

 cloud {
    organization = "my-remote-backend" # Replace with your actual org

    workspaces {
      name = "dev" # Replace with your actual workspace name
    }
  }
}


provider "aws" {
  region = var.aws_region
}