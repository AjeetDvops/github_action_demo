terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "REPLACE_WITH_STATE_BUCKET"
    key            = "lambda-cicd-demo/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lambda-cicd-demo-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "artifact_path" {
  description = "Path to the built lambda.zip artifact"
  type        = string
}

variable "app_version" {
  description = "Version/tag being deployed, e.g. the git SHA"
  type        = string
}

module "lambda_service" {
  source = "../../modules/lambda-service"

  function_name        = "lambda-cicd-demo-production"
  environment           = "production"
  artifact_path         = var.artifact_path
  artifact_hash         = filebase64sha256(var.artifact_path)
  app_version           = var.app_version
  memory_size           = 512
  timeout               = 15
  enable_function_url   = true
  log_retention_days     = 30
}

output "function_name" {
  value = module.lambda_service.function_name
}

output "function_url" {
  value = module.lambda_service.function_url
}
