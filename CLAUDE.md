# CLAUDE.md - AI Assistant Context Guide

This document provides essential context for AI assistants (like Claude) working with the Seqera Helm charts repository.

## Repository Overview

**Project**: Seqera Helm Charts
**Primary Chart**: `platform`
**Owner**: @seqeralabs/devops
**Kubernetes Requirements**: 1.33+, Helm 3.19+

This repository contains production-grade Helm charts for deploying Seqera Platform (formerly Tower) on Kubernetes with comprehensive testing and security configurations.

## Architecture Context

### Three-Pod Architecture

The platform chart deploys three separate pod types:

1. **Backend Pod** ([deployment-backend.yaml](platform/templates/deployment-backend.yaml))
   - Main application server exposing REST API
   - Handles business logic
   - Supports multiple replicas
   - Wait conditions: MySQL, Redis, Cron

2. **Cron Pod** ([deployment-cron.yaml](platform/templates/deployment-cron.yaml))
   - Handles asynchronous database operations
   - Environment creation (CE environment)
   - **IMPORTANT**: Single replica only, separate from backend
   - **Contains database migration init container** (pod that runs migrations)
   - Must start before backend pods

3. **Frontend Pod** ([deployment-frontend.yaml](platform/templates/deployment-frontend.yaml))
   - Web UI serving
   - Separate deployment for independent scaling

### External Dependencies

- **MySQL Database**: Stores all Platform data (external, required)
- **Redis Cache**: Manages caching and async jobs (external, required)

### Why Cron is Separate

The cron pod is architecturally separate from backend because:
- It runs database migrations (backend waits for cron to be ready)
- Handles asynchronous background tasks
- Must be single-replica to prevent duplicate job execution
- Different resource requirements and scaling characteristics

## Critical Development Patterns

### 1. Template Rendering with `tpl`

Many values support template evaluation using Helm's `tpl` function:

```yaml
# In values.yaml
commonLabels:
  example: "{{ .Release.Name }}-label"

# In template
{{- include "seqera.tplvalues.render" (dict "value" .Values.commonLabels "context" $) | nindent 4 }}
```

### 2. Bitnami Common Library Integration

The chart depends on [Bitnami Common Library](https://github.com/bitnami/charts/tree/main/bitnami/common)

## File Organization Guide

### Key Files

```
helm-charts/
├── platform/
│   ├── Chart.yaml                    # Chart metadata, version, dependencies
│   ├── values.yaml                   # Default values
│   ├── README.md                     # Auto-generated documentation
│   ├── README.md.gotmpl              # Documentation template used by helm-docs
│   ├── CHANGELOG.md                  # Version changelog
│   ├── Makefile                      # Build and test commands
│   │
│   ├── charts/                       # Location where subcharts will be created
│   │
│   ├── templates/                    # Kubernetes templates
│   │   ├── _helpers.tpl              # Template helper functions
│   │   ├── _common_helpers.tpl       # Platform-specific helpers
│   │   ├── deployment-backend.yaml   # Backend deployment
│   │   ├── deployment-cron.yaml      # Cron job deployment
│   │   ├── deployment-frontend.yaml  # Frontend deployment
│   │   ├── service.yaml              # Kubernetes services
│   │   ├── secret.yaml               # Secrets management
│   │   ├── configmap.yaml            # ConfigMaps
│   │   ├── serviceaccount.yaml       # Service accounts
│   │   ├── ingress.yaml              # Ingress configuration
│   │   ├── extra-list.yaml           # Extra deployment objects
│   │   └── NOTES.txt                 # Installation notes
│   │
│   └── tests/                        # Unit tests (11 files, 5,754 lines)
│       ├── deployment-backend_test.yaml
│       ├── deployment-cron_test.yaml
│       ├── deployment-frontend_test.yaml
│       ├── service_test.yaml
│       ├── secret_test.yaml
│       ├── configmap_test.yaml
│       ├── serviceaccount_test.yaml
│       ├── ingress_test.yaml
│       ├── extra-list_test.yaml
│       ├── _common_helpers_test.yaml
│       ├── NOTES_test.yaml
│       └── __snapshot__/             # Test snapshot outputs
│
├── .github/
│   ├── workflows/
│   │   └── build-helm-charts.yaml          # CI/CD pipeline
│   └── scripts/                            # Python automation
│       ├── extract_charts.py               # Identifies changed charts
│       ├── run_chart_tests.py              # Test runner
│       ├── check_chart_versions.py         # Version conflict detection
│       └── helm_unittests_files_exist.py   # Test coverage validator
│
└── .pre-commit-config.yaml           # Pre-commit hooks
```

### Template → Test Correspondence

**RULE**: Every template file MUST have a corresponding test file, for example:

| Template | Test File |
|----------|-----------|
| `deployment-backend.yaml` | `deployment-backend_test.yaml` |
| `deployment-cron.yaml` | `deployment-cron_test.yaml` |
| `deployment-frontend.yaml` | `deployment-frontend_test.yaml` |
| `service.yaml` | `service_test.yaml` |
| `secret.yaml` | `secret_test.yaml` |
| `extra-list.yaml` | `extra-list_test.yaml` |
| `_common_helpers.tpl` | `_common_helpers_test.yaml` |
| `NOTES.txt` | `NOTES_test.yaml` |

## Testing Requirements

### 100% Test Coverage Policy

**MANDATORY**: Every template must have comprehensive test coverage.

### Framework: helm-unittest

- **Plugin**: [helm-unittest](https://github.com/helm-unittest/helm-unittest) v1.0.1
- **Schema**: Tests validate against JSON schema

### Running Tests

```bash
# From within platform/ directory
make test          # Run all tests
make debug         # Run tests in debug mode

# Install plugin if missing
make install-unittest-plugin
```

### Test File Structure

```yaml
suite: test deployment-backend
templates:
  - deployment-backend.yaml
tests:
  - it: should create a Deployment
    set:
      global:
        platformExternalDomain: example.com
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.name
          value: release-name-platform-backend
```

### Test Patterns

1. **Document Count Validation**: Verify expected number of resources
2. **Resource Kind Verification**: Ensure correct Kubernetes resource types
3. **Field Value Assertions**: Check specific field values
4. **Template Rendering**: Validate template logic
5. **Conditional Logic**: Test feature flags and conditionals
6. **Integration**: Verify cross-component references

### Snapshot Testing

Snapshots stored in `tests/__snapshot__/` directory. Regenerate with:

```bash
helm unittest -u platform/
```

## Common Tasks & Workflows

### Adding a New Template

1. Create template file in `platform/templates/`
2. **MUST**: Create corresponding test file in `platform/tests/`
3. Add test suite with comprehensive coverage
4. Run `make test` to verify
5. Run pre-commit hooks: `pre-commit run --all-files`

### Modifying values.yaml

1. Update `values.yaml` with proper comments for documentation
2. Update affected templates
3. Update corresponding test files with new test cases
4. Run `make test`
5. helm-docs will auto-generate `README.md` via pre-commit hook

### Testing Changes Locally

**IMPORTANT FOR AI ASSISTANTS**: Always use unit tests to verify changes. DO NOT use `helm template`
to test changes during development as it requires multiple values to be set. The unit test suite is
comprehensive and faster.

```bash
# PRIMARY: Run unit tests (USE THIS TO VERIFY CHANGES)
make -C platform test

# Update snapshots after intentional changes
helm unittest -u platform/

# Debug specific test (when a test fails)
helm unittest -d -f tests/configmap_test.yaml platform/
```

**For manual inspection only (not for testing):**
```bash
# Render templates to inspect output (for human review only, not for automated testing)
helm template platform ./platform -f platform/values.yaml > output.yaml
```

### Version Bumping

When bumping versions, follow these steps:

1. Update `version` in the appropriate `Chart.yaml` file (chart version)
   - For platform chart: [Chart.yaml](platform/Chart.yaml)
   - For subcharts: `platform/charts/<subchart-name>/Chart.yaml`
2. Update `appVersion` in the `Chart.yaml` file (app version, if applicable)
3. **MUST**: Update the corresponding `CHANGELOG.md` file with the new version and changes:
   - For platform chart: [CHANGELOG.md](platform/CHANGELOG.md)
   - For subcharts: `platform/charts/<subchart-name>/CHANGELOG.md`
   - Add a new version section following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format
   - Document all changes under appropriate categories (Added, Changed, Deprecated, Removed, Fixed, Security)
   - Mark breaking changes with **BREAKING** prefix
   - Include migration instructions for breaking changes with before/after examples
   - Use the date format YYYY-MM-DD

**Note**: Both the main platform chart and any subcharts should maintain their own CHANGELOG.md files to track version-specific changes independently.

## Git & CI/CD Context

### Pre-commit Hooks

Configured in [.pre-commit-config.yaml](.pre-commit-config.yaml):
Install: `pre-commit install`

### GitHub Workflow: build-helm-charts.yaml

**Triggers**: Push to chart directories (e.g. platform/, platform/charts/subchart/, newchart/ etc.)

**Steps**:
1. Detect changed chart directories
2. Set up Helm
3. Extract charts to package
4. **Validate test files exist** ([helm_unittests_files_exist.py](.github/scripts/helm_unittests_files_exist.py))
5. **Check version conflicts** ([check_chart_versions.py](.github/scripts/check_chart_versions.py)) - queries OCI registry
6. **Run chart tests** ([run_chart_tests.py](.github/scripts/run_chart_tests.py)) - must pass 100%
7. Package charts
8. **Push to OCI registry** (when on master branch only)

## Known Gotchas & Important Notes

### ⚠️ Template Evaluation Timing

Templates are evaluated at render time, not at runtime. Be careful with:
- `lookup` function (queries live cluster)
- Random value generation (happens at each render)
- Secret persistence patterns (use lookup to preserve existing secrets)

## Documentation Standards

### helm-docs Auto-generation

- **Tool**: [helm-docs](https://github.com/norwoodj/helm-docs) v1.14.2
- **Template**: [README.md.gotmpl](platform/README.md.gotmpl)
- **Output**: [README.md](platform/README.md)
- **Trigger**: Pre-commit hook automatically runs helm-docs

### values.yaml Comment Formatting

Use special comments for documentation:

```yaml
# -- Description of this configuration value
# This will be extracted into the README
configKey: defaultValue

# This value won't be documented
internalKey: value
```

## Quick Command Reference

### Testing

```bash
# Run all platform tests
make -C platform test

# Debug mode
make debug

# Specific test file
helm unittest -f tests/configmap_test.yaml platform/

# Update snapshots
helm unittest -u platform/

# Check plugin installed
make check-unittest-plugin
```

### Building

```bash
# Package chart
make -C platform build

# Lint chart
helm lint platform/

# Render templates
helm template my-release platform/

# Render with custom values
helm template my-release platform/ -f custom-values.yaml

# Dry run install
helm install my-release platform/ --dry-run --debug
```

### Dependency Management

```bash
# Update dependencies
helm dependency update platform/

# List dependencies
helm dependency list platform/

# Build dependency charts
helm dependency build platform/
```

## Resources & Links

- **Helm Documentation**: https://helm.sh/docs/
- **helm-unittest**: https://github.com/helm-unittest/helm-unittest
- **Bitnami Common Library**: https://github.com/bitnami/charts/tree/main/bitnami/common
- **helm-docs**: https://github.com/norwoodj/helm-docs
- **Seqera Platform**: https://seqera.io/platform/

---

**For AI Assistants**: This document is specifically designed to provide context for AI assistants working with this codebase. When making changes, always follow the testing requirements and development patterns outlined above, and propose changes to this document when appropriate.
