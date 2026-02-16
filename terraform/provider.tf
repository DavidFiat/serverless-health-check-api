terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket = "terraform-state-serverless-health-check"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "serverless-health-check"
      ManagedBy   = "terraform"
    }
  }
}
