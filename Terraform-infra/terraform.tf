terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "pulseguard-state-bucket"
    key            = "terraform-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pulseguard-state-lock"
    encrypt        = true
  }
}