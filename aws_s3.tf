resource "random_id" "bucket_name" {
  prefix      = "demobucket"
  byte_length = 4
}

resource "aws_s3_bucket" "storage_bucket" {
  bucket        = random_id.bucket_name.dec
  force_destroy = true

  tags = {
    Name        = "demo-bucket-${local.owner_email}"
    Environment = "Demo"
    User        = "${local.owner_email}"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.storage_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
