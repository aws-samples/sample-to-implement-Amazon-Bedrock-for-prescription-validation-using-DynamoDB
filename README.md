# Prescription Validation System with Amazon Bedrock and DynamoDB

A healthcare solution that enables real-time prescription validation and drug interaction checking using Amazon Bedrock and DynamoDB.

## Overview

This solution implements a prescription validation system that enables healthcare providers to check drug interactions through natural language conversations. The system combines the power of DynamoDB's single-digit millisecond performance with Amazon Bedrock's conversational capabilities.

## Architecture

The following architecture diagram illustrates how healthcare providers interact with this data model through the prescription validation agent.

![Architecture Diagram](image.png)

The solution consists of:
- DynamoDB table with composite key design (PatientID, RecordType)
- Amazon Bedrock agent for prescription validation
- AWS Lambda function for data operations
- Amazon Bedrock knowledge base for medication data

### Workflow
1. Provider queries agent with patient ID and proposed medication
2. Agent invokes Lambda function
3. Lambda retrieves current medications from DynamoDB
4. Agent evaluates interactions using knowledge base
5. Provider receives results and can request documentation
6. Lambda records interaction check in DynamoDB

## Prerequisites

- [AWS CLI installed and configured](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Git installed](https://git-scm.com/downloads)

## Deployment

1. Clone the repository:
```bash
git clone git@ssh.gitlab.aws.dev:my-group-aditranj/terraform-dynamodb-genai-blog.git
cd     prescription-validation-with-Bedrock-using-DynamoDB
```

2. Update Knowledge Base Id in variables.tf file with Knowledge Base ID:
```bash
cd prescription-validation-with-Bedrock-using-DynamoDB/main-modules
```

```bash
# In main-module/variables.tf
variable "kb_id" {
  description = "KB ID of Kendra GenAI Index"
  type        = string
  default     = " " # Replace with your noted ID 
}
```

3. Deploy with Terraform:
```bash
terraform init
terraform plan
terraform apply
```

4. Get the S3 bucket name deployed by terraform The bucket name will be in format:` bedrock-agent-kb-{8 digit-random-suffix}`

5. Configure S3 as Data Source for knowledge base created in pre-requisite, follow the instructions in [Connect to Amazon S3 for your knowledge base](https://docs.aws.amazon.com/bedrock/latest/userguide/s3-data-source-connector.html)

6. Associate the knowledge base with the agent created by terraform ‘terraformPrescriptionValidation-namecheck-update-agent’. For more information, follow [this](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-kb-add.html) to add a knowledge base to the agent.

## Features

- Real-time prescription validation
- Natural language interaction
- Efficient medication record management
- Comprehensive audit trail
- Professional boundary maintenance
- Structured interaction results

## Data Model

The DynamoDB table uses:
- Partition key: PatientID
- Sort key: Medication
- Interaction check history

## Limitations

- Uses sample knowledge base (needs real medical data)
- Basic interaction checking only
- No dosage-specific validations
- Limited to simple drug combinations

## Cleanup

Remove deployed resources:
```bash
terraform destroy
```

## Additional Resources

- [Data modeling for DynamoDB tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/data-modeling.html)
- [Using generative AI with DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ddb-ai-integration.html)
- [Amazon DynamoDB data models for generative AI chatbots](https://aws.amazon.com/blogs/database/amazon-dynamodb-data-models-for-generative-ai-chatbots/)
- [Data modeling building blocks in DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/data-modeling-blocks.html)


## Contributing

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License
This library is licensed under the MIT-0 License. See the LICENSE file.

