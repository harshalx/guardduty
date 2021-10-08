provider "aws" {
  alias = "ume-core-security"
  assume_role {
    role_arn     = "arn:aws:iam::144302015276:role/DevOps"
    session_name = "security-session"
  }
}