# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.25.2] - 2026-01-23

### Changed

- Added warnings in `values.yaml` about Kustomize incompatibility with Helm auto-generated random values
- Simplified and improved Kustomize example documentation with prominent warning banner about explicit configuration requirements when using Kustomize

## [0.25.1] - 2026-01-23

### Added

- Added validation to ensure either `platformDatabase.password` or `platformDatabase.existingSecretName` is provided during chart installation

## [0.25.0] - 2026-01-23

### Changed

- Updated Studios subchart to version 1.1.0 (Studios application version 0.9.0)

## [0.24.1] - 2026-01-15

### Added

- Added `global.imageCredentialsSecrets` configuration to support multiple pre-existing image pull secrets
  - Allows referencing existing Kubernetes secrets of type `kubernetes.io/dockerconfigjson` for private registry authentication
  - Secrets are automatically added to the ServiceAccount's `imagePullSecrets` list
  - Complements existing `global.imageCredentials` for inline secret creation
- Added Studios template environment variables generator in tower.yml configuration
  - New `studiosTemplates` configuration section for defining interactive analysis tools (e.g., R-IDE, Jupyter, VSCode, etc.)
  - Supports tool customization with image, labels, icon, and resource requirements
  - Includes `studiosTemplatesExperimental` for experimental tool configurations
- Added `dataExplorer.enabled` toggle flag to control Data Explorer feature in Platform UI

### Changed

- Split Helm-controlled tower.yml content from user-provided content for better configuration management

### Fixed

- Fixed `secretKey` helper functions to ignore custom `existingSecretKey` when using chart-managed secrets, ensuring consistency with external secret handling pattern
  - Fixed `platform.database.secretKey` helper
  - Fixed `platform.redis.secretKey` helper
  - Fixed `platform.jwt.secretKey` helper
  - Fixed `platform.crypto.secretKey` helper
  - Fixed `platform.license.secretKey` helper
  - Fixed `platform.smtp.secretKey` helper
- Fixed cron deployment to include `TOWER_DB_PASSWORD` environment variable for database migrations

## [0.24.0] - 2026-01-13

### Added

- Added Studios subchart as a new dependency
  - Studios provides interactive analysis capabilities for Seqera Platform
  - Chart version 1.0.0, application version 0.8.0
  - Integrated as a conditional subchart (enabled via `studios.enabled`)
  - Deploys Studios server (StatefulSet) and proxy (Deployment) components
  - Includes init container to wait for Platform readiness
- Added platform URL integration test ([tests/studios_platform_url_test.yaml](platform/tests/studios_platform_url_test.yaml))
  - Validates Platform URL configuration is accessible by Studios subchart

### Changed

- Reorganized values.yaml structure
  - Moved `extraDeploy`, `commonAnnotations`, and `commonLabels` after ingress section
  - Improved logical grouping of configuration sections
- Updated dependencies to include Studios chart (version 1.x.x)
  - Repository: `file://charts/studios`
  - Condition: `studios.enabled`

## [0.23.0] - 2026-01-09

### Added

- Added `seqera-common` library chart as a dependency
  - Provides shared template helpers used across Seqera charts

### Changed

- Refactored init container templates to use `seqera-common` library helpers
  - `seqera.initContainerWaitForMySQL` - For MySQL readiness checks in backend and cron pods
  - `seqera.initContainerWaitForRedis` - For Redis readiness checks in backend and cron pods
- Updated Makefile with improved dependency management
  - `make test` now automatically rebuilds all dependencies before running tests

### Fixed

- Fixed init container template that was not using database password from secret correctly

## [0.22.0] - 2025-12-24

### Changed

- **BREAKING**: Moved `platformDatabase` configuration from `global.platformDatabase` to top-level `platformDatabase`
  - This change improves chart structure and makes database configuration more consistent with other top-level settings
  - **Migration Required**: If you are upgrading from a previous version, you must update your values files:
    - Change `global.platformDatabase.*` to `platformDatabase.*`
    - Update `global.platformDatabase.database` to `platformDatabase.name` (field renamed for clarity)
  - Example migration:
    ```yaml
    # Before (v0.21.x and earlier)
    global:
      platformDatabase:
        host: mysql.example.com
        database: platform_db
        username: platform_user
        password: secret

    # After (v0.22.0+)
    platformDatabase:
      host: mysql.example.com
      name: platform_db
      username: platform_user
      password: secret
    ```

## Earlier Versions

Changes prior to version 0.22.0 were not tracked in this changelog.
