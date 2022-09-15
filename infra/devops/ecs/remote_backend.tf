terraform {
  backend "s3" {
    bucket         = "devops-ninja-terraform"
    key            = "devops/ecs/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-ninja-terraform-locks"
    encrypt        = true
    profile        = "default"
  }
}
