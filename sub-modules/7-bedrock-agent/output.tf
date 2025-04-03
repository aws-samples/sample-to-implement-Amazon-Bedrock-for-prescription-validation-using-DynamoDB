output "bedrock_agent_arn" {
  description = "ID of the Bedrock knowledge base"
  value       = aws_bedrockagent_agent.bedrock_agent.agent_arn
}
