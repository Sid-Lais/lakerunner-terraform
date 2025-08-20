output "poc_data_bucket" {
  description = "GCS bucket for POC data storage"
  value       = google_storage_bucket.poc_data_lake.name
}

output "poc_data_bucket_url" {
  description = "URL for the POC data bucket"
  value       = google_storage_bucket.poc_data_lake.url
}

output "poc_config_bucket" {
  description = "GCS bucket for Lakerunner configuration"
  value       = google_storage_bucket.poc_config.name
}

output "poc_config_bucket_url" {
  description = "URL for the POC config bucket"
  value       = google_storage_bucket.poc_config.url
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
      Data Bucket: ${google_storage_bucket.poc_data_lake.name}
      Config Bucket: ${google_storage_bucket.poc_config.name}
    
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