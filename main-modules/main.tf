module "iam" {
  source = "../sub-modules/1-iam-roles"
  function_name     = "${var.project_name}-bedrock-agent-lambda"
  project_name      = var.project_name
  dynamodb_arn      = module.dynamodb.table_arn #change name as needed
  # collection_arn    = module.opensearch.collection_arn
  bucket_name       = module.bucket_for_knowledgebase_data_source.bucket_id
  # bedrock_agent_arn = module.bedrock_agent_and_action_group.bedrock_agent_arn #change name as needed
  depends_on = [
    module.dynamodb,
    module.bucket_for_knowledgebase_data_source
  ]
}

module "bucket_for_knowledgebase_data_source" {
    source              = "../sub-modules/2-s3-bucket"
    bucket_name         = "${var.bucket_name}"
    project_name        = var.project_name
}

module "s3_upload" {
  source = "../sub-modules/3-s3-upload"
  
  bucket_id    = module.bucket_for_knowledgebase_data_source.bucket_id
  file_path    = "../resources/sample_medical_validation.json"
  content_type = "application/json"
  project_name = var.project_name
}


module "dynamodb" {
  source = "../sub-modules/4-dynamodb"
  table_name    = "PatientMedications"
  project_name  = var.project_name
  sample_data   = [
    {
      PatientID = "1111"
      MedicationName = "lisinopril"
      Dosage = "10mg"
      Frequency = "daily"
      StartDate = "2024-01-15"
      InteractionChecks = []
    },
    {
      PatientID = "2222"
      MedicationName = "metformin"
      Dosage = "500mg"
      Frequency = "twice daily"
      StartDate = "2024-02-01"
      InteractionChecks = []
    },
    {
      PatientID = "3333"
      MedicationName = "lisinopril"
      Dosage = "20mg"
      Frequency = "daily"
      StartDate = "2024-02-15"
      InteractionChecks = []
    },
    {
      PatientID = "3333"
      MedicationName = "metformin"
      Dosage = "1000mg"
      Frequency = "twice daily"
      StartDate = "2024-02-15"
      InteractionChecks = []
    }
  ]
}




# main.tf in root folder
module "bedrockrole" {
  source = "../sub-modules/5-bedrock-role"
  
  collection_name = "bedrock-collection"
  project_name    = var.project_name
  knowledge_base_role_arn = module.iam.role_arn
}


# main.tf in root folder
# module "knowledge_base" {
#   source = "../sub-modules/6-knowledge_base"
#   name           = "kb-agent-kb"
#   project_name   = var.project_name
#   collection_arn = module.opensearch.collection_arn
#   kb_role_arn    = module.iam.role_arn
#   s3_bucket_arn  = module.bucket_for_knowledgebase_data_source.bucket_arn
#   depends_on = [module.opensearch]
# }


module "bedrock_agent_and_action_group" {
  source = "../sub-modules/7-bedrock-agent"
  function_name_lambda = "${var.project_name}-lambda-function"
  lambda_role_arn = module.iam.lambda_role_arn
  project_name   = var.project_name
  knowledge_base_id = var.kb_id
  kb_instructions_for_agent = var.kb_instructions_for_agent
  # knowledge_base_arn = module.knowledge_base.knowledge_base_arn
}





