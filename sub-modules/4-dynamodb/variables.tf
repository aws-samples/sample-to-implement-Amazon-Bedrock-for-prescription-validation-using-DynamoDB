# sub-modules/dynamodb/variables.tf
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "sample_data" {
  description = "List of patient medications to add to the table"
  type = list(object({
    PatientID = string
    MedicationName = string
    Dosage = string
    Frequency = string
    StartDate = string
    InteractionChecks = list(object({
      CheckID = string
      Timestamp = string
      ProposedMedication = string
      Result = string
      Details = string
    }))
  }))
  default = []
}

# variable "sample_data" {
#   description = "List of sample patient medications to add to the table"
#   type = list(object({
#     PatientID = string
#     CurrentMedications = list(object({
#       M = object({
#         MedicationName = object({ S = string })
#         Dosage = object({ S = string })
#         Frequency = object({ S = string })
#         StartDate = object({ S = string })
#       })
#     }))
#   }))
#   default = []
# }

