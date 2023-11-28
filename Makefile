.POSIX:
.PHONY: *
.EXPORT_ALL_VARIABLES:

KUBECONFIG = $(shell pwd)/infrastructure/kubeconfig.yaml
KUBE_CONFIG_PATH = $(KUBECONFIG)

tools:
	@docker run \
		--rm \
		--interactive \
		--tty \
		--env "KUBECONFIG=${KUBECONFIG}" \
		--env-file .env \
		--volume "/var/run/docker.sock:/var/run/docker.sock" \
		--volume $(shell pwd):$(shell pwd) \
		--volume ${HOME}/.ssh:/root/.ssh \
		--volume ${HOME}/.terraform.d:/root/.terraform.d \
		--volume homelab-tools-cache:/root/.cache \
		--volume homelab-tools-nix:/nix \
		--workdir $(shell pwd) \
		nixos/nix nix-shell

backup-secret:
	kubectl create secret generic idrivee2-secret \
		--from-literal=AWS_ACCESS_KEY_ID=${IDRIVE_ACCESS_KEY_ID} \
		--from-literal=AWS_SECRET_ACCESS_KEY=${IDRIVE_SECRET_ACCESS_KEY} \
		--from-literal=AWS_ENDPOINTS=${IDRIVE_ENDPOINTS} \
		-n longhorn-system
