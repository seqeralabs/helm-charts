.PHONY: test tests unittests unittests-no-build debug check-unittest-plugin install-unittest-plugin clean-deps clean-subchart-packages rebuild-deps rebuild-deps-force help

# Run tests (with external dependencies rebuild) - DEFAULT behavior
test: unittests
tests: test
test-no-build: unittests-no-build
tests-no-build: test-no-build

help:
	@echo "Seqera Platform Helm Chart - Available Make Targets"
	@echo ""
	@echo "Testing:"
	@echo "  make test                        - Rebuild all Platform dependencies and run tests (DEFAULT)"
	@echo "  make test-no-build               - Run tests without rebuilding dependencies"
	@echo "  make debug                       - Run tests in debug mode"
	@echo "  make unittests-update-snapshots  - Rebuild all Platform dependencies and update snapshots"
	@echo ""
	@echo "Dependency Management:"
	@echo "  make rebuild-deps                - Check and rebuild missing external dependencies (fast)"
	@echo "  make rebuild-deps-force          - Force rebuild all external dependencies (slower)"
	@echo "  make clean-deps                  - Clean all dependency tgz packages"
	@echo "  make clean-subchart-packages     - Clean only subchart tgz packages (pipeline-optimization, studios)"
	@echo ""
	@echo "Building:"
	@echo "  make build                       - Package the chart"
	@echo ""
	@echo "Plugin Management:"
	@echo "  make check-unittest-plugin       - Check if helm-unittest is installed"
	@echo "  make install-unittest-plugin     - Install helm-unittest plugin"
	@echo ""
	@echo "Note: 'make test' checks and rebuilds missing external dependencies only."
	@echo "      Subcharts are always used unpacked to avoid running tests twice."
	@echo "      Dependencies are cached - use 'make rebuild-deps-force' to force refresh."

clean-deps:
	@echo "Cleaning all dependency packages..."
	@rm -f charts/*.tgz

# Clean only subchart packages (pipeline-optimization, studios, agent-backend)
# This prevents helm unittest from running tests twice on subcharts
clean-subchart-packages:
	@echo "Cleaning subchart packages..."
	@rm -f charts/pipeline-optimization-*.tgz charts/studios-*.tgz charts/agent-backend-*.tgz

# Rebuild only external dependencies (seqera-common, bitnami common) if missing
# Subcharts (pipeline-optimization, studios, agent-backend) are kept unpacked to avoid duplicate test runs
rebuild-deps: clean-subchart-packages
	@echo "Checking external dependencies..."
	@if [ ! -f charts/common-*.tgz ] || [ ! -f charts/seqera-common-*.tgz ]; then \
		echo "Missing dependencies detected, fetching..."; \
		helm dependency update 2>&1 | grep -v "walk.go" || true; \
		echo "Cleaning subchart packages to prevent duplicate test runs..."; \
		rm -f charts/pipeline-optimization-*.tgz charts/studios-*.tgz charts/agent-backend-*.tgz; \
		echo "✓ External dependencies rebuilt successfully (subcharts remain unpacked)"; \
	else \
		echo "✓ All external dependencies already present (use 'make rebuild-deps-force' to force refresh)"; \
	fi
	@echo "Checking subchart dependencies..."
	@for subchart in pipeline-optimization studios agent-backend; do \
		if [ -d "charts/$$subchart" ]; then \
			echo "Checking dependencies for $$subchart..."; \
			if [ ! -f "charts/$$subchart/charts/common-"*.tgz ] || [ ! -f "charts/$$subchart/charts/seqera-common-"*.tgz ]; then \
				echo "Missing dependencies for $$subchart, fetching..."; \
				(cd "charts/$$subchart" && helm dependency update 2>&1 | grep -v "walk.go" || true); \
				echo "✓ Dependencies for $$subchart rebuilt successfully"; \
			else \
				echo "✓ Dependencies for $$subchart already present"; \
			fi; \
		fi; \
	done

# Force rebuild all external dependencies (ignores cache)
rebuild-deps-force: clean-subchart-packages
	@echo "Force rebuilding external dependencies (seqera-common, bitnami common)..."
	@rm -f charts/common-*.tgz charts/seqera-common-*.tgz
	@helm dependency update 2>&1 | grep -v "walk.go" || true
	@echo "Cleaning subchart packages to prevent duplicate test runs..."
	@rm -f charts/pipeline-optimization-*.tgz charts/studios-*.tgz charts/agent-backend-*.tgz
	@echo "✓ External dependencies force rebuilt successfully (subcharts remain unpacked)"
	@echo "Force rebuilding subchart dependencies..."
	@for subchart in pipeline-optimization studios agent-backend; do \
		if [ -d "charts/$$subchart" ]; then \
			echo "Force rebuilding dependencies for $$subchart..."; \
			rm -f "charts/$$subchart/charts/common-"*.tgz "charts/$$subchart/charts/seqera-common-"*.tgz; \
			(cd "charts/$$subchart" && helm dependency update 2>&1 | grep -v "walk.go" || true); \
			echo "✓ Dependencies for $$subchart force rebuilt successfully"; \
		fi; \
	done

unittests-no-build:
	@echo "Running unit tests (without rebuilding dependencies)..."
	@helm unittest .

unittests: rebuild-deps
	@echo "Running unit tests..."
	@helm unittest .

unittests-update-snapshots: rebuild-deps
	@echo "Running unit tests and updating snapshots..."
	@helm unittest -u .

debug: rebuild-deps
	@echo "Running unit tests in debug mode..."
	@helm unittest -d .

# The building is done by the GHA directly, without calling the Makefile, since we need to build
# subcharts too. This target is kept for local testing purposes.
build:
	@helm package .

# Check if helm-unittest plugin is installed
check-unittest-plugin:
	@echo "Checking if helm-unittest plugin is installed..."
	@helm plugin list | grep --color=always unittest && echo "helm-unittest plugin is installed." || (echo "helm-unittest plugin not found. Install it with: make install-unittest-plugin" && exit 1)

# Install helm-unittest plugin
install-unittest-plugin:
	@echo "Installing helm-unittest plugin..."
	@helm plugin install https://github.com/quintush/helm-unittest --version 1.0.1
