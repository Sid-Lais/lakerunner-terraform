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