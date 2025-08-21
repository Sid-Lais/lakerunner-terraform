terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = var.labels
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = var.labels
}

# Random ID for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Main Lakerunner bucket with notifications
resource "google_storage_bucket" "lakerunner" {
  name     = "lakerunner-${random_id.bucket_suffix.hex}"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = false # Simplified for POC
  }

  # Auto-cleanup for POC environment
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Pub/Sub topic for object notifications (excluding db/ path)
resource "google_pubsub_topic" "object_notifications" {
  name = "${var.project_id}-lakerunner-object-notifications"
}

# Storage notification for all objects except db/ path
resource "google_storage_notification" "object_create_notify" {
  bucket         = google_storage_bucket.lakerunner.name
  topic          = google_pubsub_topic.object_notifications.id
  event_types    = ["OBJECT_FINALIZE"]
  payload_format = "JSON_API_V1"

  # This will notify on all objects - we'll filter out db/ in the subscriber
  # GCS notifications don't support path exclusions, only inclusions
}

# Service account for Pub/Sub notifications
resource "google_service_account" "pubsub_notifications" {
  account_id   = "lakerunner-pubsub-sa"
  display_name = "Lakerunner Pub/Sub Notifications"
  description  = "Service account for handling object notifications"
}

# Grant Pub/Sub publisher permission to the storage service account
resource "google_pubsub_topic_iam_member" "storage_publisher" {
  topic  = google_pubsub_topic.object_notifications.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Get project data for the storage service account
data "google_project" "current" {}


# Flexible Network Configuration
locals {
  vpc_name    = var.create_vpc ? google_compute_network.poc_vpc[0].name : var.vpc_name
  subnet_name = var.create_vpc ? google_compute_subnetwork.poc_subnet[0].name : var.subnet_name
}

# Create VPC if requested (default for POC)
resource "google_compute_network" "poc_vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = var.vpc_name != "" ? var.vpc_name : "${var.project_id}-lakerunner-poc-vpc"
  auto_create_subnetworks = false
}

# Create subnet if creating VPC
resource "google_compute_subnetwork" "poc_subnet" {
  count         = var.create_vpc ? 1 : 0
  name          = var.subnet_name != "" ? var.subnet_name : "${var.project_id}-lakerunner-poc-subnet"
  network       = google_compute_network.poc_vpc[0].id
  ip_cidr_range = var.subnet_cidr
  region        = var.region
}

# Firewall rules for Lakerunner (only when creating VPC)
resource "google_compute_firewall" "allow_lakerunner" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.project_id}-lakerunner-poc-firewall"
  network = google_compute_network.poc_vpc[0].name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080"] # SSH, HTTP, HTTPS, and app port
  }

  source_ranges = ["0.0.0.0/0"] # POC-friendly, customers can restrict
  target_tags   = ["lakerunner-poc"]
}

# Service Account for Lakerunner
resource "google_service_account" "lakerunner_poc" {
  account_id   = "lakerunner-poc-sa"
  display_name = "Lakerunner POC Service Account"
  description  = "Service account for Lakerunner POC deployment"
}

# IAM bindings for the service account
resource "google_project_iam_member" "lakerunner_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.lakerunner_poc.email}"
}

resource "google_project_iam_member" "lakerunner_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.lakerunner_poc.email}"
}

# Optional: Simple VM for processing (disabled by default)
resource "google_compute_instance" "lakerunner_processor" {
  count        = var.enable_compute ? 1 : 0
  name         = "${var.project_id}-lakerunner-poc-vm"
  machine_type = "e2-medium" # Cost-effective for POC
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50 # GB, sufficient for POC
    }
  }

  network_interface {
    network    = local.vpc_name
    subnetwork = local.subnet_name
    access_config {} # Ephemeral public IP for POC
  }

  service_account {
    email  = google_service_account.lakerunner_poc.email
    scopes = ["cloud-platform"]
  }

  tags = ["lakerunner-poc"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
    
    # Ready for Lakerunner installation
    echo "Lakerunner POC VM ready" > /tmp/setup-complete
  EOF
}