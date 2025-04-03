
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraformPrescriptionValidation"
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
  default     = "bedrock-agent-kb"
}


variable "kb_instructions_for_agent" {
  description = "Description of the agent"
  type        = string
  default     = <<-EOT
Use Knowledge Base to verify interactions. List severity, effects, and monitoring as specified. Never give medical advice beyond reference data. State if medication isn't found.
EOT
}

# variable "function_name" {
#   description = "Function name"
#   type        = string
# }

