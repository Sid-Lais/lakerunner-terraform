#!/bin/bash
set -e

echo "🔍 Running Terraform tests..."

# Navigate to POC environment
cd terraform/environments/poc

echo "✅ terraform fmt -check"
terraform fmt -check -recursive

echo "✅ terraform validate"
terraform validate

echo "✅ terraform plan (dry-run)"
# Use our test project ID
terraform plan -var="project_id=lakerunner-terraform" -target=google_storage_bucket.poc_data_lake -target=google_storage_bucket.poc_config -out=test.plan

echo "🧹 Cleaning up test artifacts"
rm -f test.plan

echo "🎉 All tests passed!"