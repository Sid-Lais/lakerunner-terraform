# Upgrading Lakerunner Terraform

## Safe Upgrade Process

Your `terraform.tfvars` files are automatically ignored by git, so you can safely pull updates without conflicts.

### Step 1: Backup Your Settings
```bash
# Backup your current configuration
cp terraform/environments/poc/terraform.tfvars terraform.tfvars.backup
```

### Step 2: Pull Updates
```bash
git pull origin main
```

### Step 3: Check for New Settings
```bash
# Compare your settings with the latest example
diff terraform/environments/poc/terraform.tfvars terraform/environments/poc/terraform.tfvars.example
```

### Step 4: Apply Updates
```bash
cd terraform/environments/poc
terraform plan  # Review changes
terraform apply  # Apply if everything looks good
```

## What's Safe to Update

**Always Safe**: We never modify your `terraform.tfvars` files  
**Infrastructure Improvements**: New resources, better defaults  
**Provider Updates**: Newer Terraform provider versions  

## Configuration File Strategy

- `terraform.tfvars.example` - Template with latest options (we may update this)
- `terraform.tfvars` - Your custom settings (never tracked in git)
- Your settings persist through all updates

## Need Help?

If you encounter issues during upgrade, compare your `terraform.tfvars` with the latest `.example` file to see new available options.