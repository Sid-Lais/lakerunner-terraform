provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  default_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })
}