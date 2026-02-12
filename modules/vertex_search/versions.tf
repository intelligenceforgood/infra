terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
  }
}
