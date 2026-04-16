# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.2.5] - 2026-04-16

### Changed

- Bump `seqera-common` dependency to 2.1.0

## [0.2.4] - 2026-04-09

### Changed

- Point `SEQERA_PLATFORM_API_URL` to the internal Platform backend service (`platformServiceAddress`:`platformServicePort`) instead of the external domain
- Add `SEQERA_PLATFORM_APP_URL` to the portal-web chart configmap using `global.platformExternalDomain`
- Add `global.platformServiceAddress` and `global.platformServicePort` values

## [0.2.3] - 2026-04-08

### Changed

- Bumped seqera-common to 2.0.2

## [0.2.2] - 2026-04-07

### Changed

- Bumped seqera-common to 2.0.1

## [0.2.1] - 2026-04-07

### Changed

- Bumped bitnami/common dependency to 2.38.0

## [0.2.0] - 2026-04-03

### Changed

- Hardcode OAuth configuration values (`SEQERA_AUTH_DOMAIN`, `SEQERA_AUTH_WEB_CLIENT_ID`, `SEQERA_AUTH_AUDIENCE`) in the configmap template to use the `global.platformExternalDomain` value and remove the corresponding `auth0` values block from `values.yaml`.

## [0.1.2] - 2026-03-25

### Changed

- Update portal web default subdomain to ai.

## [0.1.1] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [0.1.0] - 2026-03-05

### Added

- Initial release of the portal-web subchart
