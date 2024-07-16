terraform {
  backend "s3" {
    region  = "us-east-1"
    bucket  = "greencity-terraform-state"
    key     = "stage/terraform-infra.tfstate"
    encrypt = true
    acl     = "private"
  }
}