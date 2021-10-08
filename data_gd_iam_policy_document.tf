data "aws_iam_policy_document" "gd_s3_bucket_policy_document" {
        statement {
            sid = "Deny non-HTTPS access"
            effect = "Deny"
            principals {
                type = "Service"
                identifiers = ["guardduty.amazonaws.com"]
            }
            actions = ["s3:*"]
            resources = ["arn:aws:s3:::${var.bucket_name}/*"]
            condition {
                    test = "Bool"
                    variable = "aws:SecureTransport"
                    values = [ "false" ]
            }
        }
        statement {
            sid = "Deny incorrect encryption header"
            effect = "Deny"
            principals {
                
                type = "Service"
                identifiers = ["guardduty.amazonaws.com"]
            }
            actions  = ["s3:PutObject"]
            resources = ["arn:aws:s3:::${var.bucket_name}/*"]
            condition {

                test = "StringNotEquals"
                variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
                values = ["${aws_kms_key.gd_enc_key.arn}"]
                }
        }
        statement {
            sid = "Deny unencrypted object uploads"
            effect = "Deny"
            principals {
                type = "Service"
                identifiers = [ "guardduty.amazonaws.com" ]
            }
            actions = ["s3:PutObject"]
            resources  = ["arn:aws:s3:::${var.bucket_name}/*"]
            condition {
                test = "StringNotEquals"
                variable = "s3:x-amz-server-side-encryption"
                values = ["aws:kms"]
            }
        }
        statement {
            sid  = "Allow PutObject"
            effect = "Allow"
            principals {
                type = "Service"
                identifiers = ["guardduty.amazonaws.com"]
            }
            actions = ["s3:PutObject"]
            resources = ["arn:aws:s3:::${var.bucket_name}/*"]
        }
        statement {
            sid = "Allow GetBucketLocation"
            effect = "Allow"
            principals {
                type = "Service"
                identifiers = ["guardduty.amazonaws.com"]
            }
            actions = ["s3:GetBucketLocation"]
            resources = [ "arn:aws:s3:::${var.bucket_name}" ]
        }
}

data "aws_iam_policy_document" "gd_kms_key_policy_document" {
    statement {
            sid = "Enable IAM User Permissions"
            effect = "Allow"
            principals {
                type = "AWS"
                identifiers = ["arn:aws:iam::144302015276:root"] # Why the hardcoding? Coz of Open issue https://github.com/terraform-providers/terraform-provider-aws/issues/11511
																 # No way to look up an account id by name
            }
            actions = ["kms:*"]
            resources = ["*"]
    }
    statement {
            sid = "Allow GuardDuty to use the key"
            effect = "Allow"
            principals {
                type = "Service"
                identifiers = ["guardduty.amazonaws.com"]
            }
            actions = ["kms:GenerateDataKey"]
            resources = ["*"]
    }
}