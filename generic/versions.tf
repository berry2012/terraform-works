terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }


  }

  required_version = ">= 1.3.2"
}


