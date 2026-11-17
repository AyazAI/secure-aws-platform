TERRAFORM_DIR := terraform

.PHONY: fmt validate tflint checkov tfsec gitleaks security

fmt:
	terraform fmt -check -recursive -diff

validate:
	terraform -chdir=$(TERRAFORM_DIR) init -backend=false -input=false
	terraform -chdir=$(TERRAFORM_DIR) validate

tflint:
	terraform -chdir=$(TERRAFORM_DIR) init -backend=false -input=false
	tflint --init --chdir=$(TERRAFORM_DIR)
	tflint --chdir=$(TERRAFORM_DIR)

checkov:
	checkov -d $(TERRAFORM_DIR) --framework terraform --download-external-modules false --quiet --compact
	checkov -d sample-app --framework dockerfile --quiet --compact

tfsec:
	tfsec $(TERRAFORM_DIR) --no-color

gitleaks:
	gitleaks detect --source . --redact --no-banner

security: fmt validate tflint checkov tfsec gitleaks
