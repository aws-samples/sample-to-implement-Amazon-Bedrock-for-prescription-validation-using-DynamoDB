resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PatientID"
  range_key      = "Medication"
  point_in_time_recovery {
    enabled = true
  } 

  attribute {
    name = "PatientID"
    type = "S"
  }

  attribute {
    name = "Medication"
    type = "S"
  }

  tags = {
    Name        = var.table_name
    Project     = var.project_name
  }
}

resource "aws_dynamodb_table_item" "sample_patients" {
  for_each = { for idx, item in var.sample_data : idx => item }

  table_name = aws_dynamodb_table.main.name
  hash_key   = "PatientID"
  range_key  = "Medication"

  item = jsonencode({
    PatientID = { S = each.value.PatientID }
    Medication = { S = each.value.Medication }
    Dosage = { S = each.value.Dosage }
    Frequency = { S = each.value.Frequency }
    StartDate = { S = each.value.StartDate }
    InteractionChecks = { L = [] }
  })
}

