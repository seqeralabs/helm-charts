# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-01-30

### Added

- `seqera.envVars.render` - Helper to render environment variables with all values as strings
  - Ensures Kubernetes env var value compliance (all values must be strings)
  - Handles integer values by quoting them (e.g., `12345` becomes `"12345"`)
  - Supports template evaluation in env var values
  - Supports `valueFrom` references for secrets and configmaps

## [1.1.0] - 2026-01-13

### Added

- `seqera.initContainerWaitForPlatform` - Init container helper for Seqera Platform readiness checks
  - Waits for the Platform `/health` endpoint to return "UP" status
  - Supports configurable platform host and port
  - Configurable resource limits and security contexts
  - Template evaluation support for host address

## [1.0.0] - 2026-01-08

### Added

- Initial release of seqera-common library chart
- `seqera.initContainerWaitForMySQL` - Init container helper for MySQL database readiness checks
  - Supports custom connection details and secret references
  - Configurable resource limits and security contexts
- `seqera.initContainerWaitForRedis` - Init container helper for Redis readiness checks
  - Supports URI-based connection with optional password
  - Configurable resource limits and security contexts
- `seqera.tplvalues.render` - Recursive template rendering with automatic type preservation
  - Evaluates template strings containing `{{ }}`
  - Automatically converts numeric strings to integers
  - Recursively processes maps and slices
- `seqera.images.pullSecretCredentials` - Docker registry credentials helper
  - Generates base64-encoded Docker config JSON for image pull secrets
  - Supports multiple registries with username/password/email

### Fixed

- Fixed incorrect variable reference in `seqera.initContainerWaitForRedis` (`imagePullPolicy` was using `.image.pullPolicy` instead of `.waitValues.image.pullPolicy`)
- Fixed context access in `seqera.initContainerWaitForRedis` (changed `$.Values.redis` to `.context.Values.redis`)
- Fixed missing `.waitValues` prefix for `securityContext` and `resources` in `seqera.initContainerWaitForRedis`
- Fixed template evaluation in comment blocks that was causing nil pointer errors during chart rendering
  - Removed `{{ }}` delimiters from usage examples in comments to prevent Helm from attempting to evaluate them
