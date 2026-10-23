terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Todo recurso queda marcado con Project=finops-demo: es el filtro que usan
  # los scripts de src/ y el teardown para no tocar nada ajeno al proyecto.
  default_tags {
    tags = {
      Project     = "finops-demo"
      ManagedBy   = "Terraform"
      Environment = "temporary-lab"
    }
  }
}
