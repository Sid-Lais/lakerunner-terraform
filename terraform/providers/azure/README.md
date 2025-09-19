# Azure Provider Configuration

This folder contains the Terraform provider configuration for Azure. When using the install-azure-only script, no manual changes are required here.

## Usage

- Run the installer from the repo root:

  ```bash
  ./install-azure-only
  ```

- The script will initialize and apply the Azure POC using this provider configuration.

Advanced users can review provider settings in:

- terraform/providers/azure/provider.tf
- terraform/providers/azure/versions.tf
