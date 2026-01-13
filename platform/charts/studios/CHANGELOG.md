# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
