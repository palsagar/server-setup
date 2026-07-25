.DEFAULT_GOAL := help

# macOS: fork-safety workaround for ansible's python workers
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY := YES

.PHONY: help setup provision converge test test-arm vendor

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

setup: ## Install ansible-core via uv
	uv tool install ansible-core
	ansible-galaxy collection install ansible.posix

provision: ## Provision a server: make provision HOST=1.2.3.4 KEY=~/.ssh/id_ed25519
	@[ -n "$(HOST)" ] && [ -n "$(KEY)" ] || { echo "usage: make provision HOST=<ip-or-hostname> KEY=<ssh-private-key-file>"; exit 1; }
	ansible-playbook -i '$(HOST),' -u root --private-key $(KEY) playbook.yml

converge: ## Re-run selected tags: make converge HOST=... KEY=... TAGS=tools
	@[ -n "$(HOST)" ] && [ -n "$(KEY)" ] || { echo "usage: make converge HOST=<ip-or-hostname> KEY=<ssh-private-key-file> TAGS=<tags>"; exit 1; }
	ansible-playbook -i '$(HOST),' -u root --private-key $(KEY) playbook.yml --tags '$(TAGS)'

test: ## Run the full container test matrix (amd64)
	bash bin/test.sh

test-arm: ## Run the container test matrix under QEMU (arm64)
	PLATFORM=linux/arm64 bash bin/test.sh

vendor: ## Re-vendor dotfiles from this Mac into the repo
	bash bin/vendor-dotfiles.sh
