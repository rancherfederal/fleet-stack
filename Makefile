SHELL:=/bin/bash
REQUIRED_BINARIES := ytt kubectl imgpkg kapp yq helm docker kubectx
WORKING_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
ROOT_DIR := $(shell git rev-parse --show-toplevel)
WORKLOAD_DIR := ${ROOT_DIR}/workloads
# Secrets

OPT_ARGS=""

# deploy vars
WORKLOADS_KAPP_APP_NAME=workloads
WORKLOADS_NAMESPACE=default
LOCAL_CLUSTER_NAME=local

# derivables
# RANCHER_URL := $(shell kubectl get ingress rancher -n cattle-system -o yaml | yq e .spec.rules[0].host -)
# RANCHER_IP := $(shell kubectl get ingress rancher -n cattle-system -o yaml | yq e .status.loadBalancer.ingress[0].ip -)
# BOOTSTRAP_PASSWORD := $(shell kubectl get secret --namespace cattle-system bootstrap-secret -o yaml | yq e '.data.bootstrapPassword' | base64 -d)

check-tools: ## Check to make sure you have the right tools
	$(foreach exec,$(REQUIRED_BINARIES),\
		$(if $(shell which $(exec)),,$(error "'$(exec)' not found. It is a dependency for this Makefile")))

fleet-patch: 
	@printf "\n===> Patching Fleet Bug\n";
	@kubectx $(LOCAL_CLUSTER_NAME)
	@kubectl patch ClusterGroup -n fleet-local default --type=json -p='[{"op": "remove", "path": "/spec/selector/matchLabels/name"}]'
	@kubectx -

workloads-check: check-tools
	@printf "\n===> Synchronizing Workloads with Fleet (dry-run)\n";
	@kubectx $(LOCAL_CLUSTER_NAME)
	@ytt -f workloads | kapp deploy -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) -f - 
	@kubectx -

workloads-yes: check-tools
	@printf "\n===> Synchronizing Workloads with Fleet\n";
	@kubectx $(LOCAL_CLUSTER_NAME)
	@ytt -f $(WORKLOAD_DIR) | kapp deploy -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) -f - -y 
	@kubectx -

status: check-tools
	@printf "\n===> Inspecting Running Workloads in Fleet\n";
	@kubectx $(LOCAL_CLUSTER_NAME)
	@kapp inspect -a $(WORKLOADS_KAPP_APP_NAME) -n $(WORKLOADS_NAMESPACE) 
	@kubectx -
