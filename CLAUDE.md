# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## common rules

- no emoji in source code, comments, documentation, or scripts.  emoji are OK in tests when appropriate like testing for utf-8 support.
- no advertising for Claude or Claude's creator.

## Repository Purpose

This repository provides Terraform infrastructure-as-code for deploying Lakerunner in GCP environments. It's designed primarily for customer POC (proof-of-concept) deployments, focusing on easy setup and excellent first impressions for potential customers evaluating the Lakerunner platform.

## Key Commands

- `make` or `make help` - Show available commands
- `make test` - Run full test suite (format check, validate, plan with test project)
- `make fmt` - Auto-format all Terraform files
- `make validate` - Validate Terraform configuration
- `make plan` - Run terraform plan with test project ID `lakerunner-terraform`
- `make clean` - Clean up temporary Terraform files

## Architecture Overview

### Directory Structure
```
terraform/
├── environments/poc/     # POC environment (primary focus)
├── modules/gcp/          # Reusable GCP modules (future expansion)
└── providers/gcp/        # GCP provider configuration
```

### Multi-Cloud Design
The structure is designed to support future AWS and Azure deployments, but currently focuses exclusively on GCP POC environments.

### Customer Configuration Strategy
- `terraform.tfvars.example` - Template with documented options
- `terraform.tfvars` - Customer's actual config (git-ignored for safety)
- Customers only need to change `project_id` for basic setup
- Safe upgrade path: customer configs never conflict with repo updates

### Network Flexibility
The POC environment supports two deployment patterns:
- **Default**: Creates new VPC with permissive firewall rules (easy for startups/quick POC)
- **Enterprise**: Uses existing customer VPC (`create_vpc = false`)

### Core Infrastructure Components

**Storage:**
- `app_object_store` - Main application bucket with Pub/Sub notifications
- `poc_data_lake` - General data storage bucket
- `poc_config` - Configuration storage with versioning

**Notifications:**
- GCS → Pub/Sub integration for object create events
- All notifications fire (GCS doesn't support path exclusions)
- Application must filter out `db/` path notifications in subscriber

**Compute:**
- Optional VM with Docker pre-installed (`enable_compute = false` by default)
- Uses dedicated service account with minimal required permissions

**Security:**
- Dedicated service accounts with least-privilege access
- Auto-cleanup after 30 days for POC resources
- No hardcoded credentials (uses GCP auth flow)

## Testing Strategy

Tests run without requiring real GCP credentials by using:
- Format validation (`terraform fmt -check`)
- Configuration validation (`terraform validate`)
- Targeted planning (`terraform plan -target=...`) with test project ID
- Test project ID: `lakerunner-terraform` (safe, no real resources)

## Customer Experience Focus

This infrastructure prioritizes:
1. **5-minute setup** - Minimal configuration required
2. **Professional outputs** - Clear resource information and next steps
3. **Safety** - Auto-cleanup, upgrade-safe configuration management
4. **Flexibility** - Supports both greenfield and enterprise network constraints

The POC environment is designed to make an excellent first impression for potential customers evaluating Lakerunner.
