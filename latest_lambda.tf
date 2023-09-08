terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_execpy" {
  name = "serverless_example_lambdapy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  # Attach an inline policy to grant EC2 permissions
  inline_policy {
    name = "lambda-ec2-permissions"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AttachNetworkInterface",
            "ec2:DetachNetworkInterface",
          ],
          Effect   = "Allow",
          Resource = "*",
        },
      ],
    })
  }
}

# Create the Lambda function with VPC configuration
resource "aws_lambda_function" "examplepy" {
  function_name = "Serverlessexamplepy"
  filename      = "C:\\LAMBDA_TERRAFORM\\lambda_funtion_zip.zip" # Use the output_path from the archive_file data source
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_execpy.arn

  # VPC Configuration
  vpc_config {
    subnet_ids         = ["subnet-0b71844be556dbf00"] # Use your specific subnet ID
    security_group_ids = ["sg-06beb940ee43a455e"]     # Use your specific security group ID(s)
  }
}

# IAM role permission to allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.examplepy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.examplepy.execution_arn}/*/*"
}
