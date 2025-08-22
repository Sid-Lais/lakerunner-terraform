.PHONY: help test check clean fmt validate plan

# Default target
help: ## Show this help message
	@echo "Lakerunner Terraform"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

test: ## Run all tests (format, validate, plan)
	@./test.sh

check: test ## Alias for test

fmt: ## Format Terraform files
	@echo "Formatting Terraform files..."
	@cd terraform/environments/poc && terraform fmt -recursive

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	@cd terraform/environments/poc && terraform validate

plan: ## Run terraform plan with test project ID
	@echo "Running terraform plan..."
	@cd terraform/environments/poc && terraform plan -var="project_id=lakerunner-terraform"

clean: ## Clean up temporary files
	@echo "Cleaning up..."
	@find . -name "*.tfstate*" -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.plan" -delete