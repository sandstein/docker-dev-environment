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

SHELL_SCRIPTS := bin/dde tests/bin/docker
DOCKERFILES   := $(sort $(wildcard docker/*/Dockerfile))

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: generate
generate: ## Regenerate bin/dde and bin/completions.bash from bin/src
	$(BASHLY) generate
	$(BASHLY) add completions_script --force

.PHONY: check-generated
check-generated: generate ## Fail if the generated files differ from the committed ones
	@git diff --exit-code -- bin/dde bin/completions.bash \
		|| { echo "bin/dde or bin/completions.bash is out of date: run 'make generate' and commit the result" >&2; exit 1; }

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
test: ## Run the bats test suite
	$(BATS) tests

.PHONY: check
check: check-generated lint check-compose test ## Everything CI runs
