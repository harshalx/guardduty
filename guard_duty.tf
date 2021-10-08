#Note: We have to use data sources here to avoid Terraform getting confused and continually adding and removing members
data "aws_organizations_organization" "org-master" {}

resource "aws_guardduty_detector" "org-master-detector" {
  enable = true
}

resource "aws_guardduty_organization_admin_account" "guardduty-delegate-master-account" {
  admin_account_id = data.aws_organizations_organization.org-master.master_account_id
}

resource "aws_guardduty_member" "gdmember-account" {
  depends_on         = [aws_guardduty_organization_admin_account.guardduty-delegate-master-account]
  count              = length(data.aws_organizations_organization.org-master.non_master_accounts)
  account_id         = data.aws_organizations_organization.org-master.non_master_accounts[count.index].id
  detector_id        = aws_guardduty_detector.org-master-detector.id
  email              = data.aws_organizations_organization.org-master.non_master_accounts[count.index].email
}

resource "aws_guardduty_organization_configuration" "org-conf" {
  depends_on = [aws_guardduty_organization_admin_account.guardduty-delegate-master-account]
  auto_enable = true
  detector_id = aws_guardduty_detector.org-master-detector.id
}

//TODO audit logging on bucket
resource "aws_s3_bucket" "org_gd_bucket" {
 provider = aws.ume-core-security
 bucket = var.bucket_name
 depends_on = [aws_kms_key.gd_enc_key]

 server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
 }
 policy = data.aws_iam_policy_document.gd_s3_bucket_policy_document.json
 tags = {
		  terraform = "true"
		}
}

resource "aws_s3_bucket_notification" "gd_s3_bucket_notification" {
  provider = aws.ume-core-security
  bucket = aws_s3_bucket.org_gd_bucket.id

  queue {
    queue_arn     = data.aws_sqs_queue.s3_notification_queue.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_kms_key" "gd_enc_key" {
 provider = aws.ume-core-security
 description             = "Encryption key for Guard Duty Findings"
 policy = data.aws_iam_policy_document.gd_kms_key_policy_document.json

  tags = { "name" = "gd_enc_key", 
			terraform = "true"
		 }
}

#resource "aws_kms_alias" "a" {
#  provider = aws.ume-core-security
#  name          = "alias/guard-duty-enc-key2"
#  target_key_id = aws_kms_key.gd_enc_key.key_id
#}

resource "null_resource" "plr-configure-publishing-destination" {
  triggers = {
    #Run if the script or the detector id changes
    accountsInGD = sha512("${filesha512("configure_gd_pub_dest.sh")}${aws_guardduty_detector.org-master-detector.id}")
  }

  provisioner "local-exec" {
    command = "/bin/bash configure_gd_pub_dest.sh ${aws_guardduty_detector.org-master-detector.id} ${aws_s3_bucket.org_gd_bucket.arn} ${aws_kms_key.gd_enc_key.arn}"
  }
}