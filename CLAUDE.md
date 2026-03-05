# CLAUDE.md - AI Assistant Context Guide

This document provides essential context for AI assistants working with the Seqera Helm charts repository.

## Repository Overview

**Project**: Seqera Helm Charts | **Primary Chart**: `platform` | **Owner**: @seqeralabs/devops
**Requirements**: Kubernetes 1.33+, Helm 3.19+

Production-grade Helm charts for deploying Seqera Platform (formerly Tower) on Kubernetes.

## 🚨 CRITICAL: Test Writing Rules (READ FIRST)

### Rule #1: NEVER Use Multiple Assertions for Individual Map Fields

**❌ FORBIDDEN - Do NOT write tests like this:**
```yaml
# Wrong: Multiple assertions for individual fields
- equal:
    path: metadata.labels.app
    value: my-app
- equal:
    path: metadata.labels.version
    value: v1.0.0
- equal:
    path: spec.template.spec.containers[0].env[0].name
    value: FOO
```

**✅ REQUIRED - Always assert on the entire map/list:**
```yaml
# Correct: Single assertion for the complete object
- equal:
    path: metadata.labels
    value:
      app: my-app
      version: v1.0.0

- equal:
    path: spec.template.spec.containers[0].env
    value:
      - name: FOO
        value: bar
      - name: BAZ
        value: qux
```

**Why?** More concise, validates exact structure, easier to maintain, better test failures.

### Rule #2: Use `matchSnapshot` for Full Resource Validation

```yaml
# ✅ Correct: Full resource validation
- it: should render deployment with all features
  set:
    replicas: 3
    image.tag: v1.2.3
  asserts:
    - matchSnapshot: {}

# ✅ Correct: Targeted field testing
- it: should set correct replicas
  set:
    replicas: 5
  asserts:
    - equal:
        path: spec.replicas
        value: 5
```

**When to use:**
- `matchSnapshot`: Full object validation, integration tests
- `equal`: Specific fields, conditional logic, computed values

**Update snapshots:** `helm unittest -u charts/platform/`

## Architecture

### Three-Pod Deployment
1. **Backend** - REST API, business logic, multiple replicas, waits for cron/MySQL/Redis
2. **Cron** - Single replica, runs DB migrations, async tasks, must start before backend
3. **Frontend** - Web UI, independent scaling

**External deps:** MySQL (data), Redis (cache/jobs)

## File Structure

```
charts/
└── platform/
    ├── Chart.yaml                    # Metadata, version, dependencies
    ├── values.yaml                   # Default config (comment with # -- for docs)
    ├── CHANGELOG.md                  # Version history (required on version bump)
    ├── templates/                    # K8s templates
    │   ├── _helpers.tpl             # Template helpers
    │   ├── deployment-*.yaml        # Pod deployments
    │   ├── service.yaml             # Services
    │   ├── secret.yaml              # Secrets
    │   └── ...
    └── tests/                        # Unit tests (MANDATORY)
        ├── *_test.yaml              # One test per template
        └── __snapshot__/            # Snapshot outputs
```

**RULE**: Every template MUST have a corresponding test file:
- `deployment-backend.yaml` → `deployment-backend_test.yaml`
- `secret.yaml` → `secret_test.yaml`
- `_helpers.tpl` → `_helpers_test.yaml`

## Testing (100% Coverage Required)

**Framework**: helm-unittest v1.0.1

### Run Tests
```bash
make -C charts/platform test              # Run all tests
helm unittest -u charts/platform/         # Update snapshots
helm unittest -d -f tests/configmap_test.yaml charts/platform/  # Debug specific test
```

**IMPORTANT**: Always use unit tests to verify changes. DO NOT use `helm template` during development.

### Test Structure Example
```yaml
suite: test deployment-backend
templates:
  - deployment-backend.yaml
tests:
  - it: should create a Deployment with correct labels
    set:
      global.platformExternalDomain: example.com
    asserts:
      - isKind:
          of: Deployment
      - equal:
          path: metadata.labels
          value:
            app: platform
            component: backend
```

## Critical Patterns

### External Secrets Pattern

**CRITICAL**: When users provide `existingSecretName`, DO NOT store that value in chart's Secret.

```yaml
# ❌ WRONG
data:
  MY_SECRET: {{ include "common.secrets.passwords.manage" ... }}

# ✅ CORRECT
data:
  {{- if not .Values.myComponent.existingSecretName }}
  MY_SECRET: {{ include "common.secrets.passwords.manage" ... }}
  {{- end }}
```

**Required tests:**
1. Secret included when provided inline
2. Secret NOT included when using `existingSecretName`
3. Data block is `null` when all secrets are external

See [charts/platform/templates/secret.yaml](charts/platform/templates/secret.yaml) for examples.

### Template Rendering with `tpl`

Values support template evaluation:
```yaml
# values.yaml
commonLabels:
  release: "{{ .Release.Name }}"

# template
{{- include "seqera.tplvalues.render" (dict "value" .Values.commonLabels "context" $) | nindent 4 }}
```

## Common Workflows

### Adding a New Template
1. Create template in `charts/platform/templates/`
2. **MUST**: Create test file in `charts/platform/tests/` with comprehensive coverage
3. Run `make -C charts/platform test`
4. Run `pre-commit run --all-files`

### Modifying Templates
1. Update template
2. Update corresponding test file
3. Run `make -C charts/platform test`
4. Update snapshots if needed: `helm unittest -u charts/platform/`

### Version Bumping
1. Update `version` in `Chart.yaml` (or subchart's `Chart.yaml`)
2. Update `appVersion` if applicable
3. **MUST**: Update `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
   - Use categories: Added, Changed, Deprecated, Removed, Fixed, Security
   - Prefix breaking changes with **BREAKING**
   - Include migration instructions for breaking changes
   - Date format: YYYY-MM-DD

## CI/CD Pipeline

**Triggers**: Push to chart directories
**Steps**: Extract charts → Validate tests exist → Check version conflicts → Run tests (100%) → Package → Push to OCI (master only)

**Pre-commit hooks**: Auto-runs helm-docs, generates README from `README.md.gotmpl`

## Quick Commands

```bash
# Testing
make -C charts/platform test
helm unittest -u charts/platform/

# Building
make -C charts/platform build
helm lint charts/platform/

# Dependencies
helm dependency update charts/platform/
```

## Important Notes

- **helm-docs**: Auto-generates README from values.yaml comments (use `# --` prefix)
- **Bitnami Common Library**: Chart dependency for common patterns
- **Template timing**: Evaluated at render time, not runtime (careful with `lookup`)

## Resources

- [Helm Docs](https://helm.sh/docs/)
- [helm-unittest](https://github.com/helm-unittest/helm-unittest)
- [Bitnami Common Library](https://github.com/bitnami/charts/tree/main/bitnami/common)
- [Seqera Platform](https://seqera.io/platform/)

---

**For AI Assistants**: Follow the testing rules above strictly. When writing tests, always use single `equal` assertions for complete maps/lists, and use `matchSnapshot` for full resource validation. Every template change requires corresponding test updates.
