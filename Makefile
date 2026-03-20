.PHONY: init plan apply destroy fmt validate

ENV ?= production

init:
	cd environments/$(ENV) && terraform init

plan:
	cd environments/$(ENV) && terraform plan -var-file=terraform.tfvars

apply:
	cd environments/$(ENV) && terraform apply -var-file=terraform.tfvars

destroy:
	cd environments/$(ENV) && terraform destroy -var-file=terraform.tfvars

fmt:
	terraform fmt -recursive

validate:
	@for dir in environments/*/; do \
		echo "Validating $$dir..."; \
		cd $$dir && terraform init -backend=false && terraform validate && cd ../..; \
	done
