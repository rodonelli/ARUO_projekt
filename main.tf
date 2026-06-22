terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = "cb561bac-8eae-4e86-979a-765c514af3ae"
  subscription_id = "b2dfcbbe-4a65-4df1-bf88-4f26777108d1"

  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  tags = {
    "university"  = "Algebra"
    "student"     = "student@algebra.hr"
    "environment" = "dev"
    "managed-by"  = "terraform"
  }

  storage_allowed_admin_ip_ranges = [
    for ip_range in var.allowed_admin_ip_ranges : trimsuffix(ip_range, "/32")
  ]
}
