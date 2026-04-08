# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2026-04-08

### Changed

- Fixed changelog

## [2.0.1] - 2026-04-08

### Changed

- Bumped seqera-common dependency to 2.0.2

## [2.0.0] - 2026-04-07

### Changed

- **BREAKING** Renamed `database.sslNoverify` and `platformDatabase.sslNoverify` to
  `database.tlsCaVerify` and `platformDatabase.tlsCaVerify` respectively, with inverted semantics
  (the new field defaults to `true`, meaning CA verification is enabled by default).
  Migrate by replacing `sslNoverify: true` with `tlsCaVerify: false` in your values.
- Bumped seqera-common dependency to 2.0.2

## [1.1.4] - 2026-04-07

### Added

- Add `extraEnv` and `extraVolumeMounts` to `initContainerDependencies.waitForMySQL` values, enabling CA certificate mounts and additional env vars in wait init containers
- `MYSQL_EXTRA_ARGS` example documented under `waitForMySQL.extraEnv` for passing TLS flags such as `--ssl-ca` and `--ssl-mode`
- Bumped seqera-common to 2.0.1

### Changed

- User-supplied `initContainers` now render before built-in `waitFor*` init containers, enabling cert-fetching sidecars to run before dependency checks

## [1.1.3] - 2026-03-31

### Changed

- Bumped bitnami/common dependency to 2.38.0

## [1.1.2] - 2026-03-26

### Changed

- Added missing documentation comment for `dbMigrationInitContainer.args` value

## [1.1.1] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [1.1.0] - 2026-03-04

### Added

- TLS support for MySQL database connections via new `database.enableTls`, `database.sslNoverify`,
  `database.sslCa`, `database.sslCert`, `database.sslKey` values (maps to `SWELL_DB_SSL_*` env vars)
- TLS support for Platform database connections via new `platformDatabase.enableTls`,
  `platformDatabase.sslNoverify`, `platformDatabase.sslCa`, `platformDatabase.sslCert`,
  `platformDatabase.sslKey` values (maps to `TOWER_DB_SSL_*` env vars)
- Updated app version to 0.4.13

## [1.0.1] - 2026-03-03

### Changed

- Updated chart version to 1.0.1 to mark stable release of pipeline-optimization subchart and update
  app version to latest patch version 0.4.11

## [0.3.0] - 2026-02-20

### Added

- Support for cloud-provider-specific image overrides via `global.azure.images` for all container images (main, migrate-db, wait-for-MySQL)
- Updated seqera-common to version 2.0.0

## [0.2.6] - 2026-02-10

### Changed

- Re-release to trigger build after GitHub Actions outage

## [0.2.5] - 2026-02-09

### Changed

- Updated some documentatation to align with the other charts

## [0.2.4] - 2026-01-30

### Changed

- Updated environment variable rendering to use `seqera.envVars.render` helper function instead of `seqera.tplvalues.render` for correct templating behavior

## [0.2.3] - 2026-01-30

### Changed

- Optimized unit tests for faster execution

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
