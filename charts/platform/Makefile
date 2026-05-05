.PHONY: test tests unittests unittests-no-build debug check-unittest-plugin install-unittest-plugin clean-deps clean-subchart-packages rebuild-deps rebuild-deps-and-unpack rebuild-deps-force unittests-standalone test-all help

# Run tests (with external dependencies rebuild) - DEFAULT behavior
test: test-all
tests: test
test-no-build: unittests-no-build
tests-no-build: test-no-build

# Run BOTH the parent's recursive test suite AND each standalone-installable subchart's
# tests rendered with that subchart's own values/helpers (matching how a customer would
# install it on its own). Catches helper / values divergence that the parent-recursive
# run silently masks.
test-all: unittests unittests-standalone

help:
	@echo "Seqera Platform Helm Chart - Available Make Targets"
	@echo ""
	@echo "Testing:"
	@echo "  make test                        - Rebuild all Platform dependencies and run tests (DEFAULT)"
	@echo "  make test-no-build               - Run tests without rebuilding dependencies"
	@echo "  make test-all                    - Run parent-recursive tests AND each subchart standalone"
	@echo "  make unittests-standalone        - Run each subchart's tests standalone (no parent context)"
	@echo "  make debug                       - Run tests in debug mode"
	@echo "  make unittests-update-snapshots  - Rebuild all Platform dependencies and update snapshots"
	@echo ""
	@echo "Dependency Management:"
	@echo "  make rebuild-deps                - Check and rebuild missing external dependencies (fast)"
	@echo "  make rebuild-deps-and-unpack     - Rebuild deps, unpack tarballs, and remove tgz files"
	@echo "  make rebuild-deps-force          - Force rebuild all external dependencies (slower)"
	@echo "  make clean-deps                  - Clean all dependency tgz packages"
	@echo "  make clean-subchart-packages     - Clean only subchart tgz packages (auto-detected from charts/ subdir)"
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

# Clean only subchart packages (all subdirectories under charts/)
# This prevents helm unittest from running tests twice on subcharts
clean-subchart-packages:
	@echo "Cleaning subchart packages..."
	@for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
		rm -f charts/$$subchart-*.tgz; \
	done

# Rebuild only external dependencies (seqera-common, bitnami common) if missing
# Subcharts are kept unpacked to avoid duplicate test runs
rebuild-deps: clean-subchart-packages
	@echo "Checking external dependencies..."
	@if [ ! -f charts/common-*.tgz ] || [ ! -f charts/seqera-common-*.tgz ]; then \
		echo "Missing dependencies detected, fetching..."; \
		helm dependency update 2>&1 | grep -v "walk.go" || true; \
		echo "Cleaning subchart packages to prevent duplicate test runs..."; \
		for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
			rm -f charts/$$subchart-*.tgz; \
		done; \
		echo "✓ External dependencies rebuilt successfully (subcharts remain unpacked)"; \
	else \
		echo "✓ All external dependencies already present (use 'make rebuild-deps-force' to force refresh)"; \
	fi
	@echo "Checking subchart dependencies..."
	@for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
		echo "Checking dependencies for $$subchart..."; \
		if [ ! -f "charts/$$subchart/charts/common-"*.tgz ] || [ ! -f "charts/$$subchart/charts/seqera-common-"*.tgz ]; then \
			echo "Missing dependencies for $$subchart, fetching..."; \
			(cd "charts/$$subchart" && helm dependency update 2>&1 | grep -v "walk.go" || true); \
			echo "✓ Dependencies for $$subchart rebuilt successfully"; \
		else \
			echo "✓ Dependencies for $$subchart already present"; \
		fi; \
	done

# Rebuild dependencies, unpack all tgz tarballs into charts/, then remove the tarballs
rebuild-deps-and-unpack: rebuild-deps
	@echo "Unpacking dependency tarballs..."
	@for tgz in charts/*.tgz; do \
		if [ -f "$$tgz" ]; then \
			echo "Unpacking $$tgz..."; \
			tar -xzf "$$tgz" -C charts/; \
			rm -f "$$tgz"; \
		fi; \
	done
	@for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
		for tgz in "charts/$$subchart/charts/"*.tgz; do \
			if [ -f "$$tgz" ]; then \
				echo "Unpacking $$tgz..."; \
				tar -xzf "$$tgz" -C "charts/$$subchart/charts/"; \
				rm -f "$$tgz"; \
			fi; \
		done; \
	done
	@echo "✓ All dependencies unpacked and tarballs removed"

# Force rebuild all external dependencies (ignores cache)
rebuild-deps-force: clean-subchart-packages
	@echo "Force rebuilding external dependencies (seqera-common, bitnami common)..."
	@rm -f charts/common-*.tgz charts/seqera-common-*.tgz
	@helm dependency update 2>&1 | grep -v "walk.go" || true
	@echo "Cleaning subchart packages to prevent duplicate test runs..."
	@for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
		rm -f charts/$$subchart-*.tgz; \
	done
	@echo "✓ External dependencies force rebuilt successfully (subcharts remain unpacked)"
	@echo "Force rebuilding subchart dependencies..."
	@for subchart in $$(ls -d charts/*/  2>/dev/null | xargs -I{} basename {}); do \
		echo "Force rebuilding dependencies for $$subchart..."; \
		rm -f "charts/$$subchart/charts/common-"*.tgz "charts/$$subchart/charts/seqera-common-"*.tgz; \
		(cd "charts/$$subchart" && helm dependency update 2>&1 | grep -v "walk.go" || true); \
		echo "✓ Dependencies for $$subchart force rebuilt successfully"; \
	done

unittests-no-build:
	@echo "Running unit tests (without rebuilding dependencies)..."
	@helm unittest .

unittests: rebuild-deps
	@echo "Running unit tests..."
	@helm unittest .

# Run each subchart's unit tests STANDALONE — i.e. invoke `helm unittest` from inside the
# subchart directory so its templates render with its own values.yaml / helpers, not under
# the parent's merged context. A subchart is considered "standalone-installable" if it ships
# its own `tests/` directory.
#
# This complements `unittests`: the parent-recursive run exercises the full integrated
# deployment, this target exercises each subchart as if a customer installed it on its own.
unittests-standalone: rebuild-deps
	@echo "Running unit tests for each standalone-installable subchart..."
	@failed=""; \
	for subchart_dir in charts/*/; do \
		subchart=$$(basename $$subchart_dir); \
		if [ ! -d "$$subchart_dir/tests" ]; then \
			echo "→ skipping $$subchart (no tests/ directory)"; \
			continue; \
		fi; \
		echo ""; \
		echo "→ $$subchart (standalone)"; \
		(cd "$$subchart_dir" && helm unittest .) || failed="$$failed $$subchart"; \
	done; \
	if [ -n "$$failed" ]; then \
		echo ""; \
		echo "✗ standalone tests failed for:$$failed"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "✓ all standalone subchart tests passed"

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
