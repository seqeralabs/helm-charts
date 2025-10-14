# Makefile for Tower Helm Chart Testing
.PHONY: test tests unittests check-unittest-plugin install-unittest-plugin

# Default target
test: unittests
tests: unittests

# Run all unit tests
unittests:
	@echo "Running all unit tests..."
	cd tests/
	@helm unittest .

# Check if helm-unittest plugin is installed
check-unittest-plugin:
	@echo "Checking if helm-unittest plugin is installed..."
	@helm plugin list | grep -q unittest || (echo "helm-unittest plugin not found. Install it with: make install-unittest-plugin" && exit 1)

# Install helm-unittest plugin
install-unittest-plugin:
	@echo "Installing helm-unittest plugin..."
	@helm plugin install https://github.com/quintush/helm-unittest --version 1.0.1
