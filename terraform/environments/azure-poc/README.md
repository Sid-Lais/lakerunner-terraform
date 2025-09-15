# Azure POC Environment

This folder contains Terraform configuration for deploying a proof-of-concept environment on Azure. It provisions:

- Resource Group
- Storage Account
- Virtual Network & Subnet
- Network Interface
- Linux Virtual Machine

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values.
2. Ensure provider variables are set in `providers/azure/variables.tf`.
3. Run `terraform init` in this directory.
4. Run `terraform apply` to deploy resources.

## Requirements
- Azure credentials (Service Principal)
- Terraform >= 1.0.0
- AzureRM Provider >= 3.0.0
