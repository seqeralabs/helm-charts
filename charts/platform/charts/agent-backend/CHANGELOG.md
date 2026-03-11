# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.2.3] - 2026-03-11

### Changed

- Make secrets optionals - POSTHOG_API_KEY, LANGCHAIN_API_KEY, OPENAI_API_KEY

## [0.2.2] - 2026-03-09

### Changed

- Add new env variable from secret OPENAI_API_KEY to deployment
- Update appversion to 2.0.0

## [0.2.1] - 2026-03-05

### Changed

- Changed default value for agent backend subdomain from `ai` to `ai-api`

## [0.2.0] - 2026-02-20

### Added

- Support for cloud-provider-specific image overrides via `global.azure.images` for all container images (main, init, wait-for-db)
- Updated seqera-common to version 2.0.0

## [0.1.4] - 2026-02-10

### Added

- Support for `extraDeploy` field to deploy additional custom Kubernetes resources alongside the chart

## [0.1.3] - 2026-02-10

### Changed

- Use the more correct `AGENT_BACKEND_DB_PASSWORD` env var, even though `DB_PASSWORD` is supported

## [0.1.2] - 2026-02-10

### Removed

- Remove `image.registry` and `global.imageCredentials`/`global.imageCredentialsSecrets` validations from NOTES.txt and corresponding tests

## [0.1.1] - 2026-02-10

### Changed

- Re-release to trigger build after GitHub Actions outage

## [0.1.0] - 2026-02-06

### Added

- Initial release of Agent Backend chart
