# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-01-30

### Changed

- Optimized unit tests for faster execution

## [1.1.1] - 2026-01-23

### Changed

- Added warning in `values.yaml` about Kustomize incompatibility with Helm auto-generated random values

## [1.1.0] - 2026-01-23

### Changed

- Updated Studios application version to 0.9.0

## [1.0.1] - 2026-01-15

### Added

- Added `global.imageCredentialsSecrets` configuration to support multiple pre-existing image pull secrets
  - Allows referencing existing Kubernetes secrets of type `kubernetes.io/dockerconfigjson` for private registry authentication
  - Secrets are automatically added to the ServiceAccount's `imagePullSecrets` list
  - Complements existing `global.imageCredentials` for inline secret creation

### Changed

- Changed default replica counts to 2 to improve high availability
- Updated OIDC token secret management to recreate token if missing from secret
  - Addresses scenario where Studios is enabled after initial Platform installation
- Removed component-specific labels and annotations from ConfigMap values
  - Made `commonLabels` and `commonAnnotations` more generic and reusable

### Fixed

- Fixed `studios.redis.secretKey` and `studios.oidcToken.secretKey` helpers to ignore custom `existingSecretKey` when using chart-managed secrets
- Fixed Redis environment variable mount in server StatefulSet
- Fixed `CONNECT_LOG_LEVEL` environment variable name in ConfigMap (was using incorrect variable name)

## [1.0.0] - 2026-01-13

### Added

- Initial release of Studios chart
- Helm chart for deploying Seqera Studios service (interactive analysis platform)
- Deployment templates:
  - StatefulSet for Studios server component with persistent storage
  - Deployment for Studios proxy component
- Service configuration for both server and proxy components
- Ingress support for external access
- ConfigMap for Studios configuration
- Secret management for sensitive data (OIDC tokens, encryption keys)
- ServiceAccount with configurable annotations for cloud provider integration
- Support for extra resources deployment via `extraDeploy`
- Integration with Seqera Platform as a dependency
  - Init container to wait for Platform readiness using `seqera-common` library
  - Platform URL configuration and validation
- Comprehensive test suite with 100% coverage:
  - Unit tests for all templates
  - Snapshot tests for resource validation
  - Platform URL integration tests
- Dependencies:
  - `seqera-common` library chart for shared helpers
  - Bitnami `common` library for standard helpers
