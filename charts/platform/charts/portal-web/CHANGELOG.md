# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.5.0] - 2026-07-17

### Added

- Added `serviceAccount.create` (default `true`) to control whether the chart creates its
  ServiceAccount. When `true`, the ServiceAccount named by `serviceAccount.name` is created (or a
  generated `<release>-<chart>-sa` name when unset), so a custom ServiceAccount name can now be
  created rather than only referenced.

### Changed

- Allow image `tag` fields to be specified as either a string or a number in `values.schema.json`,
  so an unquoted numeric tag (for example `tag: 8.4`) no longer fails schema validation.
- **BREAKING**: `serviceAccount.name` no longer suppresses ServiceAccount creation. Previously,
  setting `serviceAccount.name` caused the chart to skip creating a ServiceAccount and reference an
  existing one instead. Creation is now gated solely on `serviceAccount.create` (default `true`).
  Migration: if you set `serviceAccount.name` to reference an externally-managed ServiceAccount,
  also set `serviceAccount.create: false` to preserve the previous behaviour.

## [0.4.0] - 2026-07-07

### Changed

- Added `examples/standalone.yaml` with a minimal values file for deploying this chart independently.
- Bumped `appVersion` to `1.7.2`.
- Bumped `seqera-common` dependency to `3.x.x` (the library no longer exposes
  `seqera.images.image` nor honors `global.azure.images` overrides).
- Annotated `values.yaml` with `# @section` markers and switched `README.md.gotmpl` to a per-section Markdown loop, grouping the generated values table by area instead of one flat list.
- Revamp README documentation.

## [0.3.7] - 2026-06-24

### Added

- Add ArtifactHub annotations: license, links, and sign key.

## [0.3.6] - 2026-06-11

### Added

- Add chart icon.
- Auto-infer types for JSON schema values file.

## [0.3.5] - 2026-06-10

### Added

- Include Helm values JSON schema.

## [0.3.4] - 2026-06-01

### Changed

- Bump bitnami/common dependency to 2.40.0.

## [0.3.3] - 2026-05-22

### Changed

- Update portal-web application version to 1.6.0.

## [0.3.2] - 2026-05-14

### Changed

- Update portal-web application version to 1.5.0.

## [0.3.1] - 2026-05-11

### Added

- Add link to [Seqera AI prerequisites](https://docs.seqera.io/platform-enterprise/seqera-ai/prerequisites) documentation in the README.

### Changed

- Update image paths in the README and values.yaml - the chart does not hardcode `cr.seqera.io` as the registry, customers are invited to vendor the images to their private registry as well as the charts.

## [0.3.0] - 2026-05-05

- **Enhancement**: allow global configuration of Ingress options. A new `global.ingress` block (`enabled`, `path`, `defaultPathType`, `ingressClassName`, `annotations`, `extraLabels`, `tls`) lets cluster-wide Ingress defaults be set once at the parent and propagate to every subchart, removing the need to repeat controller-wide config per subchart. `enabled` is OR-merged; scalar fields fall back to global when local is unset; `annotations` and `extraLabels` are merged with local winning on key collision; `tls` is concatenated (useful for a single wildcard certificate across all services).
- Add `seqera.ingress.host` template helper in each chart's `_helpers.tpl` returning that chart's primary domain. Lets users write `external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'` once in `global.ingress.annotations` and have it resolve to the correct host per chart at render time, without hard-coding hostnames.
- Add `docs/conventions/ingress.md` documenting the Ingress conventions used across charts.

### Changed

- Update bitnami/common to 2.39.0
- **BREAKING**: Default `ingress.defaultPathType` is now `Prefix` (was `ImplementationSpecific`). With the previous default and the chart's default `path: "/"`, routing behavior depended on the ingress controller — NGINX treated it as a prefix match, AWS ALB required `/*` for the same effect, GKE applied its own interpretation. The result was the same chart and values producing different routing across clusters. `Prefix` is part of the Kubernetes Ingress spec and produces consistent prefix-match semantics across NGINX, Traefik, AWS ALB, and most modern controllers, giving users a predictable out-of-the-box experience. Users whose controller still requires `ImplementationSpecific` (e.g. older GKE) can set `global.ingress.defaultPathType: ImplementationSpecific` once at the parent.

## [0.2.8] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.2 (Redis init container log message now reports `auth set` or `auth not set`)

## [0.2.7] - 2026-04-30

### Changed

- Clear the default values for `global.platformServiceAddress` and `global.platformServicePort` so they must be explicitly set when deploying this subchart standalone. They point to the Seqera Platform backend service. When deploying as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section
- Add `NOTES.txt` validation that fails the installation when `global.platformServiceAddress` or `global.platformServicePort` are not set
- Document the Platform Service connection details as a required configuration in the README

## [0.2.6] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.1 (Redis init container no longer logs the password)

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
