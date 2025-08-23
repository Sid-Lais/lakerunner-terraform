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
  force_destroy               = true # Allow deletion even with contents

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
  name = "lakerunner-notifications-${random_id.bucket_suffix.hex}"
}

# Pull subscription for consuming object notifications
resource "google_pubsub_subscription" "lakerunner_notifications" {
  name  = "lakerunner-sub-${random_id.bucket_suffix.hex}"
  topic = google_pubsub_topic.object_notifications.name

  ack_deadline_seconds       = 20
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
  account_id   = "lakerunner-pubsub-sa-${random_id.bucket_suffix.hex}"
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


# Configuration
locals {
  vpc_name                 = var.vpc_name
  subnet_name              = var.subnet_name
  postgresql_password      = var.create_postgresql && var.postgresql_password == "" ? random_password.postgresql_password[0].result : var.postgresql_password
  postgresql_instance_name = var.postgresql_instance_name != "" ? var.postgresql_instance_name : "lakerunner-postgres-${random_id.bucket_suffix.hex}"
}

# Note: Using existing VPC and subnet specified in variables

# Service Account for Lakerunner
resource "google_service_account" "lakerunner_poc" {
  account_id   = "lakerunner-poc-sa-${random_id.bucket_suffix.hex}"
  display_name = "Lakerunner POC Service Account"
  description  = "Service account for Lakerunner POC deployment"
}

# Service Account for Kubernetes Workload Identity
resource "google_service_account" "lakerunner_k8s" {
  count        = var.enable_gke ? 1 : 0
  account_id   = "lakerunner-k8s-sa-${random_id.bucket_suffix.hex}"
  display_name = "Lakerunner Kubernetes Service Account"
  description  = "Service account for Lakerunner Kubernetes workloads via Workload Identity"
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

# Enable APIs required for Cloud SQL
resource "google_project_service" "service_networking" {
  count              = 1
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql_admin" {
  count              = 1
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Enable Kubernetes Engine API for GKE
resource "google_project_service" "container_api" {
  count              = 1
  project            = var.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
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

  depends_on = [google_project_service.service_networking, google_project_service.sql_admin]
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
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 2 # 2 AM
      update_track = "stable"
    }

    user_labels = var.labels
  }

  deletion_protection = false

  depends_on = [
    google_project_service.service_networking,
    google_project_service.sql_admin,
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
  count   = var.create_postgresql ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.lakerunner_poc.email}"
}

# IAM bindings for the Kubernetes service account
resource "google_storage_bucket_iam_member" "lakerunner_k8s_bucket_admin" {
  count  = var.enable_gke ? 1 : 0
  bucket = google_storage_bucket.lakerunner.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.lakerunner_k8s[0].email}"
}

resource "google_pubsub_subscription_iam_member" "lakerunner_k8s_subscriber" {
  count        = var.enable_gke ? 1 : 0
  subscription = google_pubsub_subscription.lakerunner_notifications.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.lakerunner_k8s[0].email}"
}

resource "google_pubsub_topic_iam_member" "lakerunner_k8s_viewer" {
  count  = var.enable_gke ? 1 : 0
  topic  = google_pubsub_topic.object_notifications.name
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.lakerunner_k8s[0].email}"
}

# Optional GKE cluster for container workloads
resource "google_container_cluster" "lakerunner_gke" {
  count    = var.enable_gke ? 1 : 0
  name     = "lakerunner-gke-${random_id.bucket_suffix.hex}"
  location = var.zone

  deletion_protection = false

  depends_on = [google_project_service.container_api]

  # Use existing VPC
  network    = "projects/${var.project_id}/global/networks/${local.vpc_name}"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${local.subnet_name}"

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Allow public endpoint for POC ease
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP allocation for pods and services - use smaller ranges for default VPC
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.4.0.0/14"
    services_ipv4_cidr_block = "10.8.0.0/20"
  }

  # Remove default node pool (we'll create our own)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Enable workload identity for future service account mappings
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Release channel for automatic updates
  release_channel {
    channel = "REGULAR"
  }
}

# Node pool for the GKE cluster
resource "google_container_node_pool" "lakerunner_nodes" {
  count      = var.enable_gke ? 1 : 0
  name       = "lakerunner-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.lakerunner_gke[0].name
  node_count = var.gke_min_nodes

  # Auto-scaling configuration
  autoscaling {
    min_node_count = var.gke_min_nodes
    max_node_count = var.gke_max_nodes
  }

  # Node configuration
  node_config {
    preemptible  = false
    spot         = var.gke_use_spot
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size_gb
    disk_type    = "pd-standard"

    # Service account for nodes
    service_account = google_service_account.lakerunner_poc.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity configuration
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags = ["lakerunner-gke"]
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Workload Identity binding for lakerunner namespace/serviceaccount
resource "google_service_account_iam_member" "lakerunner_workload_identity" {
  count              = var.enable_gke ? 1 : 0
  service_account_id = google_service_account.lakerunner_k8s[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[lakerunner/lakerunner]"
}

# HMAC keys for S3 compatibility
resource "google_storage_hmac_key" "lakerunner_s3_key" {
  service_account_email = google_service_account.lakerunner_poc.email
}
