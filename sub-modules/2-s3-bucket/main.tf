# sub-modules/s3/main.tf

resource "random_id" "timestamp" {
  byte_length = 4
}

resource "aws_s3_bucket" "kb_bucket" {
  bucket = "${var.bucket_name}-${random_id.timestamp.hex}"

  tags = {
    Name        = var.bucket_name
    Project     = var.project_name
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "kb_bucket_encryption" {
  bucket = aws_s3_bucket.kb_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "kb_bucket_access" {
  bucket = aws_s3_bucket.kb_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable ACLs
resource "aws_s3_bucket_ownership_controls" "kb_bucket_ownership" {
  bucket = aws_s3_bucket.kb_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "kb_bucket_versioning" {
  bucket = aws_s3_bucket.kb_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable access logging
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_name}-logs"

  tags = {
    Name        = "${var.bucket_name}-logs"
    Project     = var.project_name
  }
}

# add lifecycle policies and bucket logging