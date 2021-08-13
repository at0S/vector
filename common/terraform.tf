terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.4.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.53.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-infrastructure-statebucket-173ngq5oh6iyj"
    dynamodb_table = "TerraformLockTable"
    key            = "855796131942/ap-southeast-2/production/terraform.tfstate"
    region         = "ap-southeast-2"
  }
}
