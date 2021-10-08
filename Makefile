.SHELL := /bin/bash

METADATA_DOCS_FILE := "docs/metadata.md"
TARGETS_DOCS_FILE  := "docs/targets.md"

export README_INCLUDES ?= $(file://$(shell pwd)/?type=text/plain)

define pepi
    @aws-vault exec --duration 1h $(PROFILE) -- \
         docker run -it --rm \
         -e AWS_ACCESS_KEY_ID \
         -e AWS_SECRET_ACCESS_KEY \
         -e AWS_SESSION_TOKEN \
		-v "$$PWD:/data" \
		-v "$$HOME/.ssh:/home/pepi/.ssh" \
         build-repository.underwriteme.co.uk:6000/platform-engineering-pipeline-image:latest $1
endef

#####################################################################
# Private targets designed to be run within the PEPI shell
#####################################################################
init:
	@terraform init -input=false -no-color
	@terraform get -update -no-color

validate: init
	@echo Running validation on Terraform code....
	@terraform validate  -no-color
	@echo Running lint checks on Terraform code....
	@tflint

plan: 
	@echo Running plan on Terraform code....
	@terraform plan -out tfplan --var-file eu-west-1.tfvars -no-color

apply: 
	@echo Running apply on Terraform code....
	@terraform apply -lock=true -input=false -refresh=true -no-color tfplan

docs/targets: # Create list of make targets in Markdown format
	@echo Auto creating README.md....
	@rm -rf $(TARGETS_DOCS_FILE)
	@echo "## Makefile Targets" >> $(TARGETS_DOCS_FILE)
	@echo -e "The following targets are available: \n" >> $(TARGETS_DOCS_FILE)
	@echo '```' >> $(TARGETS_DOCS_FILE)
	@grep -E '^[a-zA-Z_-_\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\%-30s\ %s\n", $$1, $$2}' >> $(TARGETS_DOCS_FILE)
	@echo '```' >> $(TARGETS_DOCS_FILE)

docs: docs/targets # Auto create README.md documentaion
	@terraform-config-inspect > $(METADATA_DOCS_FILE)
	@sed -i -e '1,2d' $(METADATA_DOCS_FILE)   				# Remove first line as not needed
	@sed -i '1i# Module Specifics' $(METADATA_DOCS_FILE)	# Add title to first line
	@gomplate --file ./docs/README.md.template \
	--out README.md

#####################################################################
# Public targets designed to be run directly from the command line
#####################################################################
help:
	@grep -E '^[a-zA-Z_-_\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

docs/help: ## Create documentation help
	@echo "--------------------------------------------------------------------------"
	@echo "docs - How to create/update README.md"
	@echo "--------------------------------------------------------------------------"
	@echo "- Update README.yaml with relevant documentation"
	@echo "- Run make pepi/docs directly from your shell"
	@echo "- Alternatively from within the PEPI shell run make docs"
	@echo "- Your README.md has been created :-)"


pepi: ## Run PEPI interactive shell to start developing with all the tools or run AWS CLI commands :-)
	$(call pepi)

pepi/help: ## Help on using PEPI locally
	@echo "--------------------------------------------------------------------------"
	@echo "PEPI Help - Running Helper Targets"
	@echo "--------------------------------------------------------------------------"
	@echo "Get yourself setup on PEPI: https://build-master.underwriteme.co.uk/job/platform-engineering-pe-pipeline-image-pipeline/job/master/"
	@echo
	@echo " - Run make targets pepi/{target} directly from your shell "
	@echo " - To run the PEPI interactive shell run make pepi"
	@echo "--------------------------------------------------------------------------"

pepi/docs: ## Run PEPI docs directly from your shell
	$(call pepi,make docs)

pepi/init: ## Initialise the project
	$(call pepi,make init)

pepi/validate: ## Validate the code
	$(call pepi,make validate)

pepi/plan: ## Validate, and plan code
	$(call pepi,make plan)

pepi/apply: ## Validate, and plan code
	$(call pepi,make apply)