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
  force_destroy              = true  # Allow deletion even with contents

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

# Pull subscription for consuming object notifications
resource "google_pubsub_subscription" "lakerunner_notifications" {
  name  = "${var.project_id}-lakerunner-notifications-sub"
  topic = google_pubsub_topic.object_notifications.name
  
  ack_deadline_seconds = 20
  message_retention_duration = "604800s" # 7 days
  
  enable_exactly_once_delivery = true
  
  expiration_policy {
    ttl = "2678400s" # 31 days
  }
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

# Grant Pub/Sub subscriber permission to the Lakerunner service account
resource "google_pubsub_subscription_iam_member" "lakerunner_subscriber" {
  subscription = google_pubsub_subscription.lakerunner_notifications.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.lakerunner_poc.email}"
}

# Get project data for the storage service account
data "google_project" "current" {}


# Flexible Network Configuration
locals {
  vpc_name    = var.create_vpc ? google_compute_network.poc_vpc[0].name : var.vpc_name
  subnet_name = var.create_vpc ? google_compute_subnetwork.poc_subnet[0].name : var.subnet_name
  postgresql_password = var.create_postgresql && var.postgresql_password == "" ? random_password.postgresql_password[0].result : var.postgresql_password
  postgresql_instance_name = var.postgresql_instance_name != "" ? var.postgresql_instance_name : "${var.project_id}-lakerunner-poc-postgres"
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

# PostgreSQL Configuration

# Generate random password for PostgreSQL if not provided
resource "random_password" "postgresql_password" {
  count   = var.create_postgresql && var.postgresql_password == "" ? 1 : 0
  length  = 16
  special = false
}

# Enable Service Networking API (required for Cloud SQL private networking)
resource "google_project_service" "service_networking" {
  count   = var.create_postgresql ? 1 : 0
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

# Create VPC peering for Cloud SQL private networking
resource "google_compute_global_address" "private_ip_address" {
  count         = var.create_postgresql ? 1 : 0
  name          = "google-managed-services-${local.vpc_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/${var.project_id}/global/networks/${local.vpc_name}"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.create_postgresql ? 1 : 0
  network                 = "projects/${var.project_id}/global/networks/${local.vpc_name}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
  
  depends_on = [google_project_service.service_networking]
}

# Create PostgreSQL instance if requested
resource "google_sql_database_instance" "lakerunner_postgresql" {
  count            = var.create_postgresql ? 1 : 0
  name             = local.postgresql_instance_name
  database_version = var.postgresql_version
  region           = var.region

  settings {
    tier = var.postgresql_machine_type
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/${local.vpc_name}"
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"  # POC-friendly, use "ENCRYPTED_ONLY" for production
    }
    
    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
    
    maintenance_window {
      day          = 7  # Sunday
      hour         = 2  # 2 AM
      update_track = "stable"
    }
    
    user_labels = var.labels
  }

  deletion_protection = false  # POC-friendly, enable for production
  
  depends_on = [
    google_compute_network.poc_vpc,
    google_compute_subnetwork.poc_subnet,
    google_project_service.service_networking,
    google_service_networking_connection.private_vpc_connection
  ]

  # Ensure PostgreSQL is deleted before VPC peering
  lifecycle {
    create_before_destroy = false
  }
}

# Create PostgreSQL database
resource "google_sql_database" "lakerunner_database" {
  count    = var.create_postgresql ? 1 : 0
  name     = var.postgresql_database_name
  instance = google_sql_database_instance.lakerunner_postgresql[0].name
}

# Create configdb database for Lakerunner configuration
resource "google_sql_database" "lakerunner_configdb" {
  count    = var.create_postgresql ? 1 : 0
  name     = "configdb"
  instance = google_sql_database_instance.lakerunner_postgresql[0].name
}

# Create PostgreSQL user
resource "google_sql_user" "lakerunner_user" {
  count    = var.create_postgresql ? 1 : 0
  name     = var.postgresql_user
  instance = google_sql_database_instance.lakerunner_postgresql[0].name
  password = local.postgresql_password
}

# Grant additional permissions to the service account for database management
resource "google_project_iam_member" "lakerunner_cloudsql_client" {
  count  = var.create_postgresql ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.client"
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