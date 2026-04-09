# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.30.2] - 2026-04-16

### Changed

- Portal web chart now uses the internal backend service (`global.platformServiceAddress`:`global.platformServicePort`) instead of the public external domain
- Bump `portal-web` subchart to 0.2.4

## [0.30.1] - 2026-04-16

- `oidc.pem` and `OIDC_CLIENT_REGISTRATION_TOKEN` secrets are now always generated (previously only when `studios.enabled=true`); required from Platform v26.1 onwards

## [0.30.0] - 2026-04-08

### Added

- Mount OIDC private key secret (`connect-cert-volume` at `/data/certs`) on the cron deployment, matching the backend deployment

### Changed

- `TOWER_OIDC_PEM_PATH` moved to the shared backend/cron configmap and is now always set (previously backend-only and only when `studios.enabled=true`); required from Platform v26.1 onwards
- `connect-cert-volume` and `TOWER_OIDC_REGISTRATION_INITIAL_ACCESS_TOKEN` are now always present on the backend deployment (previously only when `studios.enabled=true`); required from Platform v26.1 onwards
- Bump `mcp` subchart to 0.3.0: rename OAuth environment variables to use `MCP_` prefix (`MCP_OAUTH_INITIAL_ACCESS_TOKEN`, `MCP_OAUTH_JWT_SECRET`, `MCP_OAUTH_ISSUER_URL`, `MCP_OAUTH_AUDIENCE`)

## [0.29.8] - 2026-04-08

### Added

- Add `initContainerDependencies.waitForPlatform` init container to the `mcp` subchart deployment, waiting for Seqera Platform to be ready before starting the MCP server

## [0.29.7] - 2026-04-08

### Changed

- Add example on how to set up TLS with custom CA certificates
- Fixed changelog

## [0.29.6] - 2026-04-08

### Added

- Add unit tests for `REDISCLI_TLS` env var on the wait-for-redis init container when `redis.enableTls` is enabled, covering backend, cron, and agent-backend deployments

## [0.29.5] - 2026-04-07

### Added

- Add TLS options to `agent-backend` subchart: `database.enableTls`, `database.tlsCaVerify`, and `database.sslCa` for configuring MySQL TLS connections

### Changed

- *BREAKING** Bump `pipeline-optimization` subchart to 2.0.0: renamed `database.sslNoverify` and `platformDatabase.sslNoverify` to `tlsCaVerify` with inverted boolean semantics

## [0.29.4] - 2026-04-07

### Added

- Add `extraEnv` and `extraVolumeMounts` to all `initContainerDependencies.waitFor*` values blocks, enabling CA certificate mounts and additional env vars in wait init containers
- Add `MYSQL_EXTRA_ARGS` env var support to `waitForMySQL`, enabling TLS flags such as `--ssl-ca` and `--ssl-mode` to be passed to the `mysql` client

### Changed

- User-supplied `initContainers` now render before built-in `waitFor*` init containers in backend, cron, and all subchart deployments, enabling use cases such as fetching CA certificates before dependency checks run
- Bump seqera-common to 2.0.1
- Bump agent-backend subchart to 0.4.2
- Bump mcp subchart to 0.2.3
- Bump pipeline-optimization subchart to 1.1.4
- Bump portal-web subchart to 0.2.2
- Bump studios subchart to 1.2.7

## [0.29.3] - 2026-04-07

### Changed

- Bump `agent-backend` subchart to 0.4.0: renamed `redis.tls` to `redis.enableTls`
- Bumped bitnami/common dependency to 2.38.0 across all subcharts

## [0.29.2] - 2026-04-02

### Changed

- **BREAKING** - Updated portal-web subchart to 0.2.0: removed configurable OAuth values (`oauth.endpoint`, `oauth.clientId`, `oauth.audience`) from portal-web subchart. Auth domain is now derived from `global.platformExternalDomain`, and client ID and audience are hardcoded to fixed values.

## [0.29.1] - 2026-03-31

### Changed

- Update documentation warning about Helm-generated random values with Kustomize
- Update Studios, MCP and agent backend charts to include updates to documentation about Helm-generated random values with Kustomize.

## [0.29.0] - 2026-03-31

### Changed

- **BREAKING** Bump MCP subchart to 0.2.0: removed support for custom OAuth provider. MCP now exclusively uses Seqera Platform as the OAuth provider. Removed values: `oauth.clientId`, `oauth.clientSecretString`, `oauth.clientSecretExistingSecretName`, `oauth.clientSecretExistingSecretKey`
- Add Seqera AI installation example
- Refine Seqera AI and MCP wording in documentation

## [0.28.3] - 2026-03-26

### Added

- Add Redis support to `agent-backend` subchart (bump to 0.3.0)

## [0.28.2] - 2026-03-25

### Changed

- Update Studios template matrix to Studios 0.11
- Update agent backend Readme removing mention of deprecated variable
- Update portal web and studios default subdomains to ai. and studios.
- Update mcp default OIDC secret key to OIDC_CLIENT_REGISTRATION_TOKEN

## [0.28.1] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [0.28.0] - 2026-03-16

### Changed

- Updated platform chart version to 0.28.0
- Added new `mcp` subchart to install the Model Context Protocol server
- Restructured OIDC initial access token functions into Platform chart

## [0.27.9] - 2026-03-19

### Changed

- Updated agent-backend subchart to version 0.2.6

## [0.27.8] - 2026-03-12

### Changed

- Updated agent-backend subchart to version 0.2.5

## [0.27.7] - 2026-03-11

### Changed

- Updated agent-backend subchart to version 0.2.4

## [0.27.6] - 2026-03-11

### Changed

- Updated agent-backend subchart to version 0.2.3

## [0.27.5] - 2026-03-09

### Changed

- Updated agent-backend subchart to version 0.2.2

## [0.27.4] - 2026-03-04

### Changed

- Updated pipeline-optimization subchart to version 1.1.0

## [0.27.3] - 2026-03-03

### Changed

- Updated platform chart version to 0.27.3
- Updated platform app version to v25.3.3
- Updated studios subchart to version 1.2.1
- Updated pipeline-optimization subchart to version 1.0.1

## [0.27.0] - 2026-02-20

### Added

- Support for cloud-provider-specific image overrides via `global.azure.images` for all container images across platform and subcharts
- Added `global.azure.images` documentation to `values.yaml` for all charts

### Changed

- Updated all image references to use `seqera.images.image` instead of `common.images.image`
- Updated `platform.frontend.image` to support cloud-provider overrides
- Updated seqera-common to version 2.0.0
- Updated agent-backend subchart to version 0.2.0
- Updated pipeline-optimization subchart to version 0.3.0
- Updated studios subchart to version 1.2.0

## [0.26.1] - 2026-02-10

### Changed

- Bump platform chart version to 0.26.1 after GH failure

## [0.26.0] - 2026-02-10

### Changed

- Re-release to trigger build after GitHub Actions outage, bump minor since we added agent-backend
- Updated agent-backend subchart to version 0.1.1
- Updated pipeline-optimization subchart to version 0.2.6
- Updated studios subchart to version 1.1.5
- Bump bitnami/common to 2.36.0

## [0.25.8] - 2026-02-09

### Fixed

- Fixed ingress template to properly handle `frontend.service.http.port` and `extraHosts[].paths[].portNumber` when provided as integers, string integers, or template expressions by adding `tpl (toString ...)` conversion
- Fixed service template to properly handle port and targetPort values for cron and frontend services when provided as integers, string integers, or template expressions

### Added

- Added comprehensive unit tests for ingress port number handling with different input types (integer, string integer, template string)

### Changed

- Updated agent-backend subchart to version 0.1.1
- Updated studios subchart to version 1.1.4

## [0.25.7] - 2026-01-30

### Changed

- Updated environment variable rendering to use `seqera.envVars.render` helper function instead of `seqera.tplvalues.render` for correct templating behavior
- Updated pipeline-optimization subchart to version 0.2.4
- Updated studios subchart to version 1.1.3

## [0.25.6] - 2026-01-30

### Changed

- Optimized unit tests for faster execution

## [0.25.4] - 2026-01-29

### Added

- Added `uge-platform` and removed `local-platform` from default list of execution backends in `platform.executionBackends`

## [0.25.3] - 2026-01-29

### Added

- Added Studios Wave custom image configuration environment variables
  - New `TOWER_DATA_STUDIO_WAVE_CUSTOM_IMAGE_REGISTRY` environment variable for specifying custom registry where Wave pushes Studios images
  - New `TOWER_DATA_STUDIO_WAVE_CUSTOM_IMAGE_REPOSITORY` environment variable for specifying custom repository where Wave pushes Studios images
  - Both variables are set from `platform.studios.customImageRegistry` and `platform.studios.customImageRepository` values respectively
  - Variables are only included when Studios is enabled

### Changed

- Data Explorer is now automatically enabled when the Studios subchart is enabled
  - Added `platform.dataExplorer.enabled` helper function to handle automatic enablement logic
  - `TOWER_DATA_EXPLORER_ENABLED` environment variable is set to `true` when either `platform.dataExplorer.enabled` or `studios.enabled` is `true`

## [0.25.2] - 2026-01-23

### Changed

- Added warnings in `values.yaml` about Kustomize incompatibility with Helm auto-generated random values
- Simplified and improved Kustomize example documentation with prominent warning banner about explicit configuration requirements when using Kustomize
- Updated Studios subchart to version 1.1.1

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
