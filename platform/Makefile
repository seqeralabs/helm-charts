.PHONY: test tests unittests unittests-no-build debug check-unittest-plugin install-unittest-plugin clean-deps rebuild-deps help

# Run tests (with seqera-common rebuild) - DEFAULT behavior
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
	@echo "  make rebuild-deps                - Rebuild all Platform dependencies"
	@echo "  make clean-deps                  - Clean dependency tgz packages"
	@echo ""
	@echo "Building:"
	@echo "  make build                       - Package the chart"
	@echo ""
	@echo "Plugin Management:"
	@echo "  make check-unittest-plugin       - Check if helm-unittest is installed"
	@echo "  make install-unittest-plugin     - Install helm-unittest plugin"
	@echo ""
	@echo "Note: 'make test' always rebuilds seqera-common to ensure latest changes."
	@echo "      Use 'make test-no-build' if you know dependencies are up to date."

clean-deps:
	@echo "Cleaning dependency packages..."
	@rm -f charts/*.tgz

# Rebuild all local dependencies from source
rebuild-deps: clean-deps
	@echo "Rebuilding all local dependencies..."
	@helm dependency build 2>&1 | grep -v "walk.go" || true
	@echo "✓ All dependencies rebuilt successfully"

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
