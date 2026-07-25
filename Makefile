.DEFAULT_GOAL := help

# macOS: python forks using SSL crash without this (url lookup → github .keys)
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY := YES

.PHONY: help setup provision converge test test-arm vendor

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

setup: ## Install ansible-core via uv
	uv tool install ansible-core
	ansible-galaxy collection install ansible.posix

provision: ## Provision a server: make provision HOST=1.2.3.4
	@[ -n "$(HOST)" ] || { echo "usage: make provision HOST=<ip-or-hostname>"; exit 1; }
	ansible-playbook -i '$(HOST),' -u root playbook.yml

converge: ## Re-run selected tags: make converge HOST=... TAGS=tools
	@[ -n "$(HOST)" ] || { echo "usage: make converge HOST=<ip-or-hostname> TAGS=<tags>"; exit 1; }
	ansible-playbook -i '$(HOST),' -u root playbook.yml --tags '$(TAGS)'

test: ## Run the full container test matrix (amd64)
	bash bin/test.sh

test-arm: ## Run the container test matrix under QEMU (arm64)
	PLATFORM=linux/arm64 bash bin/test.sh

vendor: ## Re-vendor dotfiles from this Mac into the repo
	bash bin/vendor-dotfiles.sh
