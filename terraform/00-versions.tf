terraform {
  required_version = "1.5.7"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.124.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.45.0"
    }
  }

  backend "s3" {
    endpoint                    = "storage.yandexcloud.net"
    bucket                      = "<your_tf_bucket>"
    region                      = "ru-central1"
    key                         = "state.json"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

provider "aws" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

provider "yandex" {
  zone = "ru-central1-a"
}
