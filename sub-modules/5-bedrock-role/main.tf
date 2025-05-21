#IAM role for bedrock:

resource "aws_iam_role" "bedrock_role" {
  name = "AmazonBedrockExecutionRoleForKB-${var.collection_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.this.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}




resource "aws_iam_role_policy" "bedrock_access" {
  name = "BedrockAccessPolicy"
  role = aws_iam_role.bedrock_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:ListCustomModels",
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${data.aws_region.this.name}::foundation-model/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "S3AccessForKnowledgeBase"
  role = aws_iam_role.bedrock_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Describe*",
          "s3-object-lambda:Get*",
          "s3-object-lambda:List*"
        ]
        Resource = [
          "arn:aws:s3:::${var.collection_name}-${data.aws_caller_identity.this.account_id}",
          "arn:aws:s3:::${var.collection_name}-${data.aws_caller_identity.this.account_id}/*"
        ]
      }
    ]
  })
}

