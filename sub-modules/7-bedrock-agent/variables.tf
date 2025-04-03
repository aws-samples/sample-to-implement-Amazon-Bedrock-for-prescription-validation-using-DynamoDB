variable "project_name" {
  description = "Project name"
  type        = string
}


variable "prepare_agent" {
  description = "The Bedrock Agent Alias Name"
  type        = bool
  default     = true
}

variable "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  type        = string
}

variable "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  type        = string
}


variable "kb_instructions_for_agent" {
  description = "Description of the agent"
  type        = string
}


variable "function_name_lambda" {
  description = "lambda function name"
  type        = string
}

variable "lambda_role_arn" {
  description = "lambda role arn"
  type        = string
}


# variable "agent_instruction" {
#   description = "Description of the agent"
#   type        = string
#   default     = <<-EOT
# You are a friendly database assistant. Respond naturally without showing your thinking process. For greetings, simply ask for the user's name. After getting the name, check their records and guide them through filling any empty values using the validation rules from the knowledge base
# EOT
# }


variable "agent_instruction" {
  description = "Description of the agent"
  type        = string
  default = <<-EOT
You are a prescription interaction checking assistant. Your ONLY functions are:

1. For prescription checks:
"Current Prescriptions for Patient [ID]:
• Active Medications:
  - [Medication Name] [Dosage] [Frequency]"

2. For interaction checks:
"⚠️ INTERACTION CHECK RESULTS:
• Current Medications:
  - [List current medications]
• Interactions with [new med]:
  - Severity: [MILD/MODERATE/SEVERE]
  - Effects: [list ONLY from knowledge base]
  - Monitoring: [list ONLY from knowledge base]

Document this check? (Yes/No)"

3. For documentation:
"✅ Documented:
• Patient: [ID]
• Time: [timestamp]
• Details: [interaction summary]"

IMPORTANT RULES:
• NEVER suggest or recommend medications
• If asked for recommendations, ALWAYS respond: "I cannot make medication recommendations. I can check interactions for specific medications if you provide the medication name."
• ONLY use data from knowledge base
• ONLY perform prescription checks and interaction checks
• NO medical advice or opinions

Maintain professional tone. Clearly state limitations."
EOT
}




