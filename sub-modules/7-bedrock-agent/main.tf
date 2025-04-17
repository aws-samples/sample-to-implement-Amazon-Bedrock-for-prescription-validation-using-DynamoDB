data "aws_iam_policy_document" "example_agent_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["bedrock.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "example_agent_permissions" {
  statement {
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
      ]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
    ]
  }
}

data "aws_iam_policy_document" "guardrail_permissions" {
  statement {
    sid    = "ApplyGuardrail"
    effect = "Allow"
    actions = [
      "bedrock:ApplyGuardrail"
    ]
    resources = [
      "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:guardrail/*"
    ]
  }
}


data "aws_iam_policy_document" "kb_permissions" {
  statement {
    actions = ["bedrock:Retrieve","bedrock:RetrieveAndGenerate"]
    resources = [
      "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}",
    ]
  }
}



# Guardrail for Amazon Bedrock agent
resource "aws_bedrock_guardrail" "guardrail_for_agent" {
  name                      = "GuardrailPrescriptionValidation"
  blocked_input_messaging   = "This input contains sensitive information that cannot be processed. Please remove personal identifiable information and try again."
  blocked_outputs_messaging = "The response contains sensitive information and has been blocked. Please contact administrator."
  description               = "Guardrail for prescription validation agent to mask PII and mask inappropriate content"

  sensitive_information_policy_config {
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "NAME"
    }
    pii_entities_config {
      action = "ANONYMIZE"
      type   = "EMAIL"
    }
    pii_entities_config {
      action = "BLOCK"
      type   = "US_SOCIAL_SECURITY_NUMBER"
    }
  }
  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "HATE"
    }
  }
}

#Lambda for action group
# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../resources/lambda.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "main" {
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = var.function_name_lambda
  role                           = var.lambda_role_arn
  handler                        = "lambda.lambda_handler"
  runtime                        = "python3.9"
  reserved_concurrent_executions = 10
  timeout                        = 90
  tags                           = {
    Name                         = var.function_name_lambda
    Project                      = var.project_name
  }
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "terraformPrescriptionValidation-PatientMedications"
    }
  }
  }



# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 365

  tags = {
    Name        = "${var.function_name_lambda}-logs"
    Project     = var.project_name
  }
}


resource "aws_iam_role" "example" {
  assume_role_policy = data.aws_iam_policy_document.example_agent_trust.json
  name_prefix        = "AmazonBedrockExecutionRoleForAgents_"
}

resource "aws_iam_role_policy" "example" {
  policy = data.aws_iam_policy_document.example_agent_permissions.json
  role   = aws_iam_role.example.id
}

resource "aws_iam_role_policy" "guardrail_permissions" {
  policy = data.aws_iam_policy_document.guardrail_permissions.json
  role   = aws_iam_role.example.id
}

resource "aws_iam_role_policy" "kb_access_policy" {
  policy = data.aws_iam_policy_document.kb_permissions.json
  role   = aws_iam_role.example.id
}



resource "aws_bedrockagent_agent" "bedrock_agent" {
  agent_name                  = "${var.project_name}-namecheck-update-agent"
  prepare_agent               = var.prepare_agent
  agent_resource_role_arn     = aws_iam_role.example.arn
  idle_session_ttl_in_seconds = 500
  foundation_model            = "anthropic.claude-3-sonnet-20240229-v1:0"
  instruction                = var.agent_instruction
  guardrail_configuration {
    guardrail_identifier = aws_bedrock_guardrail.guardrail_for_agent.guardrail_id
    guardrail_version    = "DRAFT"
  }
}


resource "aws_lambda_permission" "bedrock_invoke" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.bedrock_agent.agent_arn
}


resource "aws_bedrockagent_agent_action_group" "bedrock_agent_actiongroup" {
  action_group_name          = "${var.project_name}-action-group"
  agent_id                   = aws_bedrockagent_agent.bedrock_agent.id
  agent_version              = "DRAFT"
  description                = "Action group fro interacting with lambda"
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.main.arn
  }
  api_schema {
    payload = file("../resources/api_schema.yaml")
  }
}

# resource "aws_bedrockagent_agent_knowledge_base_association" "bedrock_agent_kb_association" {
#   agent_id             = aws_bedrockagent_agent.bedrock_agent.agent_id
#   description          = var.kb_instructions_for_agent
#   knowledge_base_id    = var.knowledge_base_id
#   knowledge_base_state = "ENABLED"
# }


# resource "null_resource" "agent_prepare" {
#   triggers = {
#     agent_state        = sha256(jsonencode(aws_bedrockagent_agent.bedrock_agent))
#     action_group_state = sha256(jsonencode(aws_bedrockagent_agent_action_group.bedrock_agent_actiongroup))
#     kb_assoc_state     = sha256(jsonencode(aws_bedrockagent_agent_knowledge_base_association.bedrock_agent_kb_association))
#   }
#   provisioner "local-exec" {
#     command = "aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.bedrock_agent.id}"
#   }
#   depends_on = [
#     aws_bedrockagent_agent.bedrock_agent,
#     aws_bedrockagent_agent_action_group.bedrock_agent_actiongroup,
#     aws_bedrockagent_agent_knowledge_base_association.bedrock_agent_kb_association
#   ]
# }

# resource "time_sleep" "agent_api_sleep" {
#   create_duration = "60s"
#   depends_on      = [null_resource.agent_prepare]
# }


# Enabling Model Invocation logging for Amazon Bedrock Agent Interaction

resource "aws_cloudwatch_log_group" "model_invocation_log_group" {
  name = "bedrock_agent_model_invocation_log_group"
}

# IAM Role for Bedrock Model Invocation Logging to CLoudwatch

resource "aws_iam_role" "bedrock_logging" {
  name = "bedrock-model-invocation-logging"
  
  # Trust relationship policy using data sources
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
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "bedrock_logging_policy" {
  name = "bedrock-logging-policy"
  role = aws_iam_role.bedrock_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutModelInvocationLoggingConfiguration"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*:*:*"
      }
    ]
  })
}


resource "aws_bedrock_model_invocation_logging_configuration" "example" {
  depends_on = [
    aws_cloudwatch_log_group.model_invocation_log_group
  ]

  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true
    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.model_invocation_log_group.name
      role_arn = aws_iam_role.bedrock_logging.arn
    }
  }
}

