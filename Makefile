SHELL:=/bin/bash
REQUIRED_BINARIES := ytt kubectl imgpkg kapp yq helm docker rancher 
WORKING_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ROOT_DIR := $(shell git rev-parse --show-toplevel)
WORKLOAD_DIR := ${ROOT_DIR}/workloads
# Secrets

OPT_ARGS=""

# deploy vars
WORKLOADS_KAPP_APP_NAME=workloads
WORKLOADS_NAMESPACE=default

# derivables
# RANCHER_URL := $(shell kubectl get ingress rancher -n cattle-system -o yaml | yq e .spec.rules[0].host -)
# RANCHER_IP := $(shell kubectl get ingress rancher -n cattle-system -o yaml | yq e .status.loadBalancer.ingress[0].ip -)
# BOOTSTRAP_PASSWORD := $(shell kubectl get secret --namespace cattle-system bootstrap-secret -o yaml | yq e '.data.bootstrapPassword' | base64 -d)

check-tools: ## Check to make sure you have the right tools
	$(foreach exec,$(REQUIRED_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. It is a dependency for this Makefile")))

workloads-check: check-tools
	@printf "\n===> Synchronizing Workloads with Fleet (dry-run)\n";
	@ytt -f workloads | kapp deploy -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) -f - $(OPT_ARGS)

workloads-yes: check-tools
	@printf "\n===> Synchronizing Workloads with Fleet\n";
	@ytt -f $(WORKLOAD_DIR) | kapp deploy -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) -f - -y $(OPT_ARGS)

status: check-tools
	@printf "\n===> Inspecting Running Workloads in Fleet\n";
	@kapp inspect -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) $(OPT_ARGS)
