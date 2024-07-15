terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "greencity-terraform-state"
    key            = "stage/terraform-greencity-argocd.tfstate"
    encrypt        = true
    acl            = "private"
  }
}