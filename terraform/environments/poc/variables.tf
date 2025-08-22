variable "project_id" {
  description = "The GCP project ID for your POC environment"
  type        = string
}

variable "region" {
  description = "GCP region for POC resources (choose closest to you)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for POC resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "poc"
}

variable "labels" {
  description = "Labels to apply to all taggable resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "create_vpc" {
  description = "Create new VPC (true) or use existing VPC (false)"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "VPC name - used for new VPC creation or existing VPC reference"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name - used for new subnet creation or existing subnet reference"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR range for new subnet (only used when create_vpc=true)"
  type        = string
  default     = "10.0.0.0/24"
}

# Compute Configuration
variable "enable_compute" {
  description = "Enable compute resources (useful for processing nodes)"
  type        = bool
  default     = false
}

# PostgreSQL Configuration
variable "create_postgresql" {
  description = "Create new PostgreSQL instance (true) or use existing (false)"
  type        = bool
  default     = true
}

variable "postgresql_instance_name" {
  description = "PostgreSQL instance name - used for new instance creation or existing instance reference"
  type        = string
  default     = ""
}

variable "postgresql_database_name" {
  description = "PostgreSQL database name for Lakerunner"
  type        = string
  default     = "lakerunner"
}

variable "postgresql_user" {
  description = "PostgreSQL username for Lakerunner"
  type        = string
  default     = "lakerunner"
}

variable "postgresql_password" {
  description = "PostgreSQL password for Lakerunner (leave empty for auto-generation)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgresql_machine_type" {
  description = "PostgreSQL machine type (db-f1-micro for POC, db-n1-standard-1 for production)"
  type        = string
  default     = "db-f1-micro"
}

variable "postgresql_disk_size_gb" {
  description = "PostgreSQL disk size in GB"
  type        = number
  default     = 10
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_16"
}