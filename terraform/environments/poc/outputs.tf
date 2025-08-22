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

# VM outputs (when enabled)
output "vm_external_ip" {
  description = "External IP of the processing VM (when enabled)"
  value       = var.enable_compute ? google_compute_instance.lakerunner_processor[0].network_interface[0].access_config[0].nat_ip : null
}

output "vm_name" {
  description = "Name of the processing VM (when enabled)"
  value       = var.enable_compute ? google_compute_instance.lakerunner_processor[0].name : null
}

output "deployment_summary" {
  description = "POC deployment summary"
  value       = <<-EOT
    
    🎉 POC Environment Ready!
    
    Storage:
      Lakerunner Bucket: ${google_storage_bucket.lakerunner.name}
      Notifications Topic: ${google_pubsub_topic.object_notifications.name}
    
          ${var.create_postgresql ? "Database:\n      PostgreSQL Instance: ${google_sql_database_instance.lakerunner_postgresql[0].name}\n      Databases: ${var.postgresql_database_name}, configdb\n      User: ${var.postgresql_user}\n      Private IP: ${google_sql_database_instance.lakerunner_postgresql[0].private_ip_address}\n      ✅ Both lrdb and configdb ready for Lakerunner" : "💡 Enable PostgreSQL with create_postgresql=true for database support"}
    
    Network:
      VPC: ${local.vpc_name}
      Subnet: ${local.subnet_name}
      ${var.create_vpc ? "✅ New VPC created with open firewall rules" : "ℹ️  Using existing VPC (configure firewall as needed)"}
    
    Identity:
      Service Account: ${google_service_account.lakerunner_poc.email}
    
    ${var.enable_compute ? "Compute:\n      VM IP: ${google_compute_instance.lakerunner_processor[0].network_interface[0].access_config[0].nat_ip}\n      VM Name: ${google_compute_instance.lakerunner_processor[0].name}\n      ✅ Docker pre-installed" : "💡 Enable compute with enable_compute=true for a ready-to-go VM"}
    
    📝 Remember: POC resources auto-delete after 30 days
  EOT
}