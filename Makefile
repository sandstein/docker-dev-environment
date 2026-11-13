# Development tasks for dde itself (not for projects using dde).
#
# Every tool runs in a pinned docker image by default, so nothing has to be
# installed locally. Override a tool to use a local binary, e.g.
#
#   make test BATS=bats
#   make lint-shell SHELLCHECK=shellcheck

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

BASHLY_IMAGE     := dannyben/bashly:1.4.0
BATS_IMAGE       := bats/bats:1.11.1
SHELLCHECK_IMAGE := koalaman/shellcheck:v0.10.0
HADOLINT_IMAGE   := hadolint/hadolint:v2.12.0

DOCKER_RUN := docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR):/work" -w /work

BASHLY     ?= docker run --rm --user $(shell id -u):$(shell id -g) -v "$(CURDIR)/bin:/app" $(BASHLY_IMAGE)
BATS       ?= $(DOCKER_RUN) $(BATS_IMAGE)
SHELLCHECK ?= $(DOCKER_RUN) $(SHELLCHECK_IMAGE)
HADOLINT   ?= $(DOCKER_RUN) $(HADOLINT_IMAGE) hadolint
PYTHON     ?= python3

SHELL_SCRIPTS := bin/dde tests/bin/docker docker/php-cli/install-tools.sh docker/php-cli/entrypoint.sh
DOCKERFILES   := $(sort $(wildcard docker/*/Dockerfile))

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

GENERATED := bin/dde bin/completions.bash docker-compose.yml compose

.PHONY: generate
generate: ## Regenerate bin/dde, completions and the compose files
	$(BASHLY) generate
	$(BASHLY) add completions_script --force
	$(PYTHON) tools/generate.py

.PHONY: check-generated
check-generated: generate ## Fail if generated files differ from the git index
	@changes="$$(git status --porcelain -- $(GENERATED) | awk 'substr($$0, 2, 1) != " "')"; \
	if [[ -n "$${changes}" ]]; then \
		echo "generated files are out of date (run 'make generate' and git add the result):" >&2; \
		echo "$${changes}" >&2; \
		exit 1; \
	fi

.PHONY: lint
lint: lint-shell lint-docker ## Run all linters

.PHONY: lint-shell
lint-shell: ## Lint the generated dde script and the test helpers with shellcheck
	$(SHELLCHECK) -S warning $(SHELL_SCRIPTS)

.PHONY: lint-docker
lint-docker: ## Lint all Dockerfiles with hadolint
	$(HADOLINT) $(DOCKERFILES)

.PHONY: check-compose
check-compose: ## Validate the compose model (names, mounts, ports, variables)
	$(PYTHON) tools/check-compose.py

.PHONY: test
test: test-bats test-python ## Run all tests

.PHONY: test-bats
test-bats: ## Run the bats suite (CLI)
	$(BATS) tests

.PHONY: test-python
test-python: ## Run the python unit tests (generator)
	$(PYTHON) -m unittest discover -s tests

.PHONY: check
check: check-generated lint check-compose test ## Everything CI runs
