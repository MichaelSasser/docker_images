set positional-arguments

lint: lint-docker lint-shell lint-yaml

lint-docker:
	@echo "=== hadolint ==="
	hadolint ubuntu/Dockerfile

lint-shell:
	@echo "=== shellcheck ==="
	shellcheck -x ubuntu/setup/helpers/*.sh ubuntu/setup/*.sh

lint-yaml:
	@echo "=== yamllint ==="
	yamllint -s -c .yamllint.yaml .
