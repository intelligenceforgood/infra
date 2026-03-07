.PHONY: init plan apply destroy

INIT_FLAGS ?=

init:
	terraform init $(INIT_FLAGS)

plan:
	terraform plan -var-file=local-overrides.tfvars

apply:
	terraform apply -var-file=local-overrides.tfvars -auto-approve

# Usage: make import ADDR='module.foo.resource.name["key"]' ID='projects/x/...' 
import:
	terraform import -var-file=local-overrides.tfvars '$(ADDR)' '$(ID)'

destroy:
	@echo "ERROR: Run destroy manually to prevent accidents."
	@exit 1
