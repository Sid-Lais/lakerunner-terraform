# Lakerunner Azure POC — One-command install

This environment deploys a proof-of-concept on Azure. Use the install-azure-only script to provision everything—no manual Terraform steps needed.

## Prerequisites
- Azure subscription with sufficient permissions (Contributor or Owner)
- Azure CLI installed and logged in
  - az login
  - az account set --subscription "<your-subscription-id-or-name>"
- Bash shell (Linux/macOS or WSL)

## Quick Start
From the repository root:
```bash
./install-azure-only
```

The script handles initialization, planning, and applying the Azure POC using sensible defaults defined in:
- terraform/environments/azure-poc/variables.tf

If the script supports flags, run:
```bash
./install-azure-only -h
```
to see available options.

## What gets created
- Resource Group
- Storage Account + private container (lakerunner)
- Event Grid → Storage Queue for BlobCreated notifications (db/ excluded)
- Virtual Network, Subnet, NAT Gateway, NSG
- Optional: PostgreSQL Flexible Server (create_postgresql)
- Optional: AKS cluster (enable_aks)
- Optional: Event Hubs (Kafka-compatible) topics (enable_kafka)
- Optional: Convenience VM (create_vm)

## Outputs
The script prints useful outputs at the end, including:
- storage_account_name
- lakerunner_container_url
- event_queue_name
- postgresql_connection_string (if PostgreSQL enabled)
- aks_cluster_name (if AKS enabled)
- kafka_bootstrap_server, kafka_topics (if Kafka enabled)

## Cleanup
Use the uninstall/destroy option of the install-azure-only script if provided (see ./install-azure-only -h).
