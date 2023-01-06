terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
    }
  }
}

variable "GCP_PROJECT_ID" {
  type = string
}
variable "GCP_REGION" {
  type    = string
  default = "europe-west9"
}
variable "GCP_ZONE" {
  type    = string
  default = "europe-west9-a"
}
variable "GCP_IAP_SUPPORT_EMAIL" {
  type = string
}
variable "APPLICATION_TITLE" {
  type    = string
  default = "default-application"
}
variable "CLOUD_RUN_IMAGE" {
  type = string
}
variable "GCP_IAP_OAUTH_CLIENT_ID" {
  type = string
}
variable "GCP_IAP_OAUTH_CLIENT_SECRET" {
  type = string
}
variable "GCP_LB_DOMAIN" {
  type = string
}

variable "ssl" {
  type    = bool
  default = true
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
  zone    = var.GCP_ZONE
}
provider "google-beta" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
  zone    = var.GCP_ZONE
}

# Configure IAP Consent Screen.
# See: https://cloud.google.com/iap/docs/enabling-compute-howto
resource "google_iap_brand" "project_brand" {
  project           = var.GCP_PROJECT_ID
  support_email     = var.GCP_IAP_SUPPORT_EMAIL
  application_title = var.APPLICATION_TITLE
}

# Set up a cloud run service
# With Ingress Configured as internal and cloud load balancing
# (as recommended by [the google documentation](https://cloud.google.com/iap/docs/enabling-cloud-run#configuring_to_limit_access))
resource "google_cloud_run_service" "default" {
  name     = "cloudrun-srv"
  location = var.GCP_REGION

  template {
    spec {
      containers {
        image = var.CLOUD_RUN_IMAGE
      }
    }
  }
  metadata {
    annotations = {
      # Internal and Cloud Load Balancing means that external resources and users go through the load balancer
      # but internal resources can access the cloud run service directly. 
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# This module contains the entire configuration of the load balancer
# It uses SSL (with a Google Managed Certificate) and activates the IAP on the load balancer
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.3"
  name    = "cloud-run-external-lb"
  project = var.GCP_PROJECT_ID

  ssl                             = var.ssl
  managed_ssl_certificate_domains = [var.GCP_LB_DOMAIN]
  https_redirect                  = var.ssl

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = true
        oauth2_client_id     = var.GCP_IAP_OAUTH_CLIENT_ID
        oauth2_client_secret = var.GCP_IAP_OAUTH_CLIENT_SECRET
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}

# Configures a Back-end for the Load Balancer 
# https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.GCP_REGION
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

# A current limitation of this solution, as stated in https://cloud.google.com/iap/docs/enabling-cloud-run#known_limitations
# is that IAM must be configured to grant `allUsers` the Invoker role on the Cloud Run Service
# Which means :
# 1. Users accessing through the internet don't have access (since they must go through the Load Balancer (as configured in the "google_cloud_run_service" "default" resource))
# 2. All resources that are considered "internal" can still access the cloud run services directly.
resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_service.default.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}