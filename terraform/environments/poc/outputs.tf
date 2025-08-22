# Main Lakerunner bucket outputs
output "lakerunner_bucket" {
  description = "Main Lakerunner bucket name"
  value       = google_storage_bucket.lakerunner.name
}

output "lakerunner_bucket_url" {
  description = "URL for the Lakerunner bucket"
  value       = google_storage_bucket.lakerunner.url
}

output "object_notifications_topic" {
  description = "Pub/Sub topic for object notifications"
  value       = google_pubsub_topic.object_notifications.name
}


output "project_id" {
  description = "GCP Project ID used for this POC"
  value       = var.project_id
}

output "region" {
  description = "GCP Region used for this POC"
  value       = var.region
}

# Network outputs
output "vpc_name" {
  description = "VPC name (created or existing)"
  value       = local.vpc_name
}

output "subnet_name" {
  description = "Subnet name (created or existing)"
  value       = local.subnet_name
}

# Service Account outputs
output "service_account_email" {
  description = "Lakerunner service account email"
  value       = google_service_account.lakerunner_poc.email
}

# PostgreSQL outputs
output "postgresql_instance_name" {
  description = "PostgreSQL instance name (created or existing)"
  value       = var.create_postgresql ? google_sql_database_instance.lakerunner_postgresql[0].name : var.postgresql_instance_name
}

output "postgresql_connection_name" {
  description = "PostgreSQL connection name for Cloud SQL Proxy"
  value       = var.create_postgresql ? google_sql_database_instance.lakerunner_postgresql[0].connection_name : null
}

output "postgresql_private_ip_address" {
  description = "PostgreSQL private IP address"
  value       = var.create_postgresql ? google_sql_database_instance.lakerunner_postgresql[0].private_ip_address : null
}

output "postgresql_database_name" {
  description = "PostgreSQL database name"
  value       = var.postgresql_database_name
}

output "postgresql_configdb_name" {
  description = "PostgreSQL configdb name"
  value       = "configdb"
}

output "postgresql_user" {
  description = "PostgreSQL username"
  value       = var.postgresql_user
}

output "postgresql_password" {
  description = "PostgreSQL password (auto-generated if not provided)"
  value       = local.postgresql_password
  sensitive   = true
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string for applications"
  value       = var.create_postgresql ? "postgresql://${var.postgresql_user}:${local.postgresql_password}@${google_sql_database_instance.lakerunner_postgresql[0].private_ip_address}:5432/${var.postgresql_database_name}" : null
  sensitive   = true
}

# GKE outputs (when enabled)
output "gke_cluster_name" {
  description = "Name of the GKE cluster (when enabled)"
  value       = var.enable_gke ? google_container_cluster.lakerunner_gke[0].name : null
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint (when enabled)"
  value       = var.enable_gke ? google_container_cluster.lakerunner_gke[0].endpoint : null
  sensitive   = true
}

output "gke_cluster_location" {
  description = "GKE cluster location (when enabled)"
  value       = var.enable_gke ? google_container_cluster.lakerunner_gke[0].location : null
}

output "kubectl_command" {
  description = "Command to configure kubectl (when GKE enabled)"
  value       = var.enable_gke ? "gcloud container clusters get-credentials ${google_container_cluster.lakerunner_gke[0].name} --zone=${google_container_cluster.lakerunner_gke[0].location} --project=${var.project_id}" : null
}

output "deployment_summary" {
  description = "POC deployment summary"
  value       = <<-EOT
    
    POC Environment Ready!
    
    Storage:
      Lakerunner Bucket: ${google_storage_bucket.lakerunner.name}
      Notifications Topic: ${google_pubsub_topic.object_notifications.name}
    
          ${var.create_postgresql ? "Database:\n      PostgreSQL Instance: ${google_sql_database_instance.lakerunner_postgresql[0].name}\n      Databases: ${var.postgresql_database_name}, configdb\n      User: ${var.postgresql_user}\n      Private IP: ${google_sql_database_instance.lakerunner_postgresql[0].private_ip_address}\n      Both lrdb and configdb ready for Lakerunner" : "Enable PostgreSQL with create_postgresql=true for database support"}
    
    Network:
      VPC: ${local.vpc_name}
      Subnet: ${local.subnet_name}
      Using existing VPC: ${local.vpc_name}
    
    Identity:
      Service Account: ${google_service_account.lakerunner_poc.email}
    
    ${var.enable_gke ? "Kubernetes:\n      GKE Cluster: ${google_container_cluster.lakerunner_gke[0].name}\n      Location: ${google_container_cluster.lakerunner_gke[0].location}\n      Nodes: ${var.gke_min_nodes}-${var.gke_max_nodes} ${var.gke_machine_type}\n      kubectl: gcloud container clusters get-credentials ${google_container_cluster.lakerunner_gke[0].name} --zone=${google_container_cluster.lakerunner_gke[0].location}" : "Enable Kubernetes with enable_gke=true for container workloads"}
    
    Remember: POC resources auto-delete after 30 days
  EOT
}