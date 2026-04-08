# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.5] - 2026-04-08

### Added

- Add `initContainerDependencies.waitForPlatform` init container to wait for Seqera Platform to be ready before starting the MCP server
- Add `global.platformServiceAddress` and `global.platformServicePort` values for configuring the Platform service endpoint

## [0.2.4] - 2026-04-08

### Changed

- Bumped seqera-common to 2.0.2

## [0.2.3] - 2026-04-07

### Changed

- Bumped seqera-common to 2.0.1

## [0.2.2] - 2026-03-31

### Changed

- Bumped bitnami/common dependency to 2.38.0

## [0.2.1] - 2026-03-31

### Changed

- Update documentation warning about Helm-generated random values with Kustomize

## [0.2.0] - 2026-03-31

### Removed

- Refine OAuth and installation wording in chart documentation
- **BREAKING** Removed support for custom OAuth provider configuration. MCP now exclusively uses Seqera Platform as the OAuth provider. The following values have been removed: `micronautEnvironments` option `oauth`, `oauth.clientId`, `oauth.clientSecretString`, `oauth.clientSecretExistingSecretName`, `oauth.clientSecretExistingSecretKey`

## [0.1.2] - 2026-03-25

### Changed

- Update oidc initial token secret key to match platform and studios default values

## [0.1.1] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [0.1.0] - 2026-03-16

### Added

- Initial release of MCP chart
