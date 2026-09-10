terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "artifact_path" {
  description = "Path to the local zip artifact to deploy"
  type        = string
}

variable "artifact_hash" {
  description = "Base64 sha256 of the artifact, used to trigger updates"
  type        = string
}

variable "handler" {
  description = "Lambda handler entrypoint"
  type        = string
  default     = "bootstrap"
}

variable "runtime" {
  description = "Lambda runtime identifier"
  type        = string
  default     = "provided.al2023"
}

variable "architecture" {
  description = "Lambda instruction set architecture"
  type        = string
  default     = "arm64"
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 10
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "app_version" {
  description = "Version identifier baked into the function's environment variables"
  type        = string
  default     = "unknown"
}

variable "enable_function_url" {
  description = "Whether to expose a public Lambda Function URL for smoke testing"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "lambda-cicd-demo"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.function_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.handler
  runtime          = var.runtime
  architectures    = [var.architecture]
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = var.artifact_path
  source_code_hash = var.artifact_hash

  environment {
    variables = {
      APP_VERSION = var.app_version
      ENVIRONMENT = var.environment
    }
  }

  tags = local.tags

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

resource "aws_lambda_function_url" "this" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  qualifier          = aws_lambda_alias.live.name
  authorization_type = "NONE"
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "function_version" {
  value = aws_lambda_function.this.version
}

output "alias_arn" {
  value = aws_lambda_alias.live.arn
}

output "function_url" {
  value = var.enable_function_url ? aws_lambda_function_url.this[0].function_url : null
}
