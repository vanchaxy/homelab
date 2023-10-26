.PHONY: cloud boot cluster console

default: cloud boot cluster

~/.ssh/id_ed25519:
	ssh-keygen -t ed25519 -P '' -f "$@"

cloud: ~/.ssh/id_ed25519
	terraform -chdir=cloud init
	terraform -chdir=cloud apply -auto-approve -var "ansible_inventory_path=$(shell pwd)/inventories"

cloud-destroy: ~/.ssh/id_ed25519
	terraform -chdir=cloud destroy -var "ansible_inventory_path=$(shell pwd)/inventories"

boot: ~/.ssh/id_ed25519
	ansible-playbook \
		--inventory inventories \
		boot.yml

cluster: ~/.ssh/id_ed25519
	ansible-playbook \
		--inventory inventories \
		cluster.yml

console:
	ansible-console \
		--inventory inventories
