terraform {
  backend "s3" {
    bucket         = "ume-mcb-terraform-states"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
    key            = "guardduty.terraform.tfstate"
  }
}