# AI-Powered Incident Response Infrastructure
# S3 bucket for log storage and Lambda function for Bedrock analysis

# S3 Bucket for incident logs
resource "aws_s3_bucket" "incident_logs" {
  bucket = "${var.project_name}-incident-logs-${random_string.bucket_suffix.result}"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-incident-logs"
    Purpose = "incident-response-logs"
  })
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "incident_logs" {
  bucket = aws_s3_bucket.incident_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "incident_logs" {
  bucket = aws_s3_bucket.incident_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "incident_logs" {
  bucket = aws_s3_bucket.incident_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Lambda function
resource "aws_iam_role" "incident_analyzer_lambda" {
  name = "${var.project_name}-incident-analyzer-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM policy for Lambda to access S3 and Bedrock
resource "aws_iam_role_policy" "incident_analyzer_lambda" {
  name = "${var.project_name}-incident-analyzer-lambda-policy"
  role = aws_iam_role.incident_analyzer_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.incident_logs.arn,
          "${aws_s3_bucket.incident_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
                              Resource = [
                          "arn:aws:bedrock:us-west-1::foundation-model/anthropic.claude-sonnet-4-20250514-v1:0"
                      ]
      }
    ]
  })
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "incident_analyzer_lambda" {
  name              = "/aws/lambda/${var.project_name}-incident-analyzer"
  retention_in_days = 7

  tags = var.common_tags
}

# Lambda function for incident analysis
resource "aws_lambda_function" "incident_analyzer" {
  filename         = "../lambda/incident-analyzer.zip"
  function_name    = "${var.project_name}-incident-analyzer"
  role            = aws_iam_role.incident_analyzer_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.incident_logs.bucket
      BEDROCK_MODEL = "anthropic.claude-sonnet-4-20250514-v1:0"
    }
  }

  tags = var.common_tags

  depends_on = [
    aws_iam_role_policy.incident_analyzer_lambda,
    aws_cloudwatch_log_group.incident_analyzer_lambda
  ]
}

# Outputs
output "incident_logs_bucket" {
  description = "S3 bucket for incident logs"
  value       = aws_s3_bucket.incident_logs.bucket
}

output "incident_analyzer_lambda" {
  description = "Lambda function for incident analysis"
  value       = aws_lambda_function.incident_analyzer.function_name
} 