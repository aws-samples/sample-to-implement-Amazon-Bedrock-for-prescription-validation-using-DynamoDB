resource "aws_s3_object" "validation_rules" {
  bucket = var.bucket_id
  key    = "sample_medical_validation.json"
  source = var.file_path
  
  content_type = var.content_type
  
  tags = {
    Name        = "sample_medical_validation"
    Project     = var.project_name
  }
}
