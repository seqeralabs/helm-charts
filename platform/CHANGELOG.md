# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
