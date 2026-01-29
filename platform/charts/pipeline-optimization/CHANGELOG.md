# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-01-29

### Added

- Added `extraDeploy` configuration to support deploying additional Kubernetes resources alongside pipeline-optimization

## [0.2.1] - 2026-01-15

### Added

- Added `global.imageCredentialsSecrets` configuration to support multiple pre-existing image pull secrets
  - Allows referencing existing Kubernetes secrets of type `kubernetes.io/dockerconfigjson` for private registry authentication
  - Secrets are automatically added to the ServiceAccount's `imagePullSecrets` list
  - Complements existing `global.imageCredentials` for inline secret creation

### Fixed

- Fixed `secretKey` helper functions to ignore custom `existingSecretKey` when using chart-managed secrets, ensuring consistency with external secret handling pattern
  - Fixed `pipeline-optimization.database.secretKey` helper
  - Fixed `pipeline-optimization.platformDatabase.secretKey` helper

## [0.2.0] - 2026-01-09

### Added

- Added `seqera-common` library chart as a dependency
  - Provides shared template helpers used across Seqera charts

### Changed

- Updated chart maintainer information and documentation
- Updated copyright headers to include 2025-2026

## [0.1.0] - 2024-12-24

### Added

- Initial release of pipeline-optimization subchart
- Helm chart for deploying Seqera Pipeline Optimization service (Groundswell)
- Support for custom image configuration
- Support for service configuration
- Basic deployment templates
- Integration with platform chart as a subchart
