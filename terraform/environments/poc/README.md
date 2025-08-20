# Lakerunner POC Environment

## Quick Start (5 minutes)

This Terraform configuration creates a minimal GCP environment perfect for evaluating Lakerunner.

### Prerequisites
- GCP Project with billing enabled
- Terraform installed (`brew install terraform` on macOS)
- GCP CLI authenticated (`gcloud auth application-default login`)

### Setup Steps

1. **Configure your environment**:
   ```bash
   cd terraform/environments/poc
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** - only change the project_id:
   ```hcl
   project_id = "your-actual-gcp-project-id"
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform apply
   ```

4. **Note the outputs** - you'll need the bucket names for Lakerunner installation

### What Gets Created

- **Data Bucket**: For storing your evaluation data
- **Config Bucket**: For Lakerunner configuration files  
- **Auto-cleanup**: Resources automatically delete after 30 days

### What You Get
After `terraform apply` completes, the output will show all created resources including storage buckets, network configuration, and service accounts.

### Upgrading
Your configuration is safe during upgrades - see [UPGRADE.md](../../../UPGRADE.md) for details.

### Cleanup
```bash
terraform destroy
```