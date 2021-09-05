//AWSとterraformとの連携を記述するファイル
provider "aws" {
  region = "ap-northeast-1"

  # AWSリソースの共通タグ
  default_tags {
    tags = {
      Env    = "prod"
      System = "example"
    }
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.42.0"
    }
  }

  # 使用するterraformのバージョン
  required_version = "1.0.0"
}
