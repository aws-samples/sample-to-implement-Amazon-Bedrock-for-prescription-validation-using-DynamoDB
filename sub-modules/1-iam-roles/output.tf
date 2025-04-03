# sub-modules/iam/outputs.tf
output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.kb_role.arn
}
