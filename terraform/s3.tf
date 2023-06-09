module "www_bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = "www.${var.bucket_name}"
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  acl                      = "public-read"
  attach_policy            = true

  policy = templatefile(
    "templates/s3_policy.json",
    {
      bucket_name = "www.${var.bucket_name}",
      referer_key = random_password.www_referer_key.result
    }
  )

  website = {
    index_document = "index.html"
  }
  cors_rule = [
    {
      allowed_headers = ["Authorization", "Content-Length"]
      allowed_methods = ["GET", "POST"]
      allowed_origins = ["https://www.${var.domain_name}"]
      max_age_seconds = 3000
    }
  ]
}

module "root_bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = var.bucket_name
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  acl                      = "public-read"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  attach_policy            = true

  policy = templatefile(
    "templates/s3_policy.json",
    {
      bucket_name = "${var.bucket_name}",
      referer_key = random_password.root_referer_key.result
    }
  )

  website = {
    redirect_all_requests_to = {
      host_name = "www.${var.domain_name}"
      protocol  = "https"
    }
  }
}

resource "aws_s3_bucket_notification" "www_bucket" {
  bucket      = module.www_bucket.s3_bucket_id
  eventbridge = true
}
