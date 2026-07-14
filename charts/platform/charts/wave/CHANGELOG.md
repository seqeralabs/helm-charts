# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `serviceAccount.create` (default `true`) to control whether the chart creates its
  ServiceAccount. When `true`, the ServiceAccount named by `serviceAccount.name` is created (or a
  generated `<release>-<chart>-sa` name when unset), so a custom ServiceAccount name can now be
  created rather than only referenced.

### Changed

- **BREAKING**: `serviceAccount.name` no longer suppresses ServiceAccount creation. Previously,
  setting `serviceAccount.name` caused the chart to skip creating a ServiceAccount and reference an
  existing one instead. Creation is now gated solely on `serviceAccount.create` (default `true`).
  Migration: if you set `serviceAccount.name` to reference an externally-managed ServiceAccount,
  also set `serviceAccount.create: false` to preserve the previous behaviour.

## [0.3.0] - 2026-07-07

### Changed

- Added `examples/standalone.yaml` with a minimal values file for deploying this chart independently.
- Bumped `appVersion` to `v1.35.0`.
- Refresh deployment snapshot after `platformServiceAddress` requirement (#131).
- Annotated `values.yaml` with `# @section` markers and switched `README.md.gotmpl` to a per-section Markdown loop, grouping the generated values table by area instead of one flat list.
- Revamp README documentation.

### Removed

- **BREAKING**: Removed `global.azure.images` image overrides for the `wave` container, its
  `touch-config-file` init container, and the `waitForPostgres`/`waitForRedis` init containers.
  Deployments now resolve images through `common.images.image` only.
- Bumped `seqera-common` dependency to `3.x.x`.

## [0.2.7] - 2026-06-24

### Added

- Add ArtifactHub annotations: license, links, and sign key.

## [0.2.6] - 2026-06-11

### Added

- Add chart icon.
- Auto-infer types for JSON schema values file.

## [0.2.5] - 2026-06-10

### Added

- Include Helm values JSON schema.

## [0.2.4] - 2026-06-01

### Changed

- Bump bitnami/common dependency to 2.40.0.

## [0.2.3] - 2026-05-15

### Changed

- Rename `redis.db` to `redis.database` for consistency with other charts (value was not actually referenced in any wave template yet).

## [0.2.2] - 2026-05-13

### Changed

- Update image path to `cr.seqera.io/enterprise/wave/server`.

## [0.2.1] - 2026-05-12

### Changed

- Update image paths in the README and values.yaml - the chart does not hardcode `cr.seqera.io` as the registry, customers are invited to vendor the images to their private registry as well as the charts.

## [0.2.0] - 2026-05-05

- **Enhancement**: allow global configuration of Ingress options. A new `global.ingress` block (`enabled`, `path`, `defaultPathType`, `ingressClassName`, `annotations`, `extraLabels`, `tls`) lets cluster-wide Ingress defaults be set once at the parent and propagate to every subchart, removing the need to repeat controller-wide config per subchart. `enabled` is OR-merged; scalar fields fall back to global when local is unset; `annotations` and `extraLabels` are merged with local winning on key collision; `tls` is concatenated (useful for a single wildcard certificate across all services).
- Add `seqera.ingress.host` template helper in each chart's `_helpers.tpl` returning that chart's primary domain. Lets users write `external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'` once in `global.ingress.annotations` and have it resolve to the correct host per chart at render time, without hard-coding hostnames.
- Add `docs/conventions/ingress.md` documenting the Ingress conventions used across charts.

### Changed

- Update bitnami/common to 2.39.0
- **BREAKING**: Default `ingress.defaultPathType` is now `Prefix` (was `ImplementationSpecific`). With the previous default and the chart's default `path: "/"`, routing behavior depended on the ingress controller — NGINX treated it as a prefix match, AWS ALB required `/*` for the same effect, GKE applied its own interpretation. The result was the same chart and values producing different routing across clusters. `Prefix` is part of the Kubernetes Ingress spec and produces consistent prefix-match semantics across NGINX, Traefik, AWS ALB, and most modern controllers, giving users a predictable out-of-the-box experience. Users whose controller still requires `ImplementationSpecific` (e.g. older GKE) can set `global.ingress.defaultPathType: ImplementationSpecific` once at the parent.

## [0.1.2] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.2 (Redis init container log message now reports `auth set` or `auth not set`)

## [0.1.1] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.1 (Redis init container no longer logs the password)

## [0.1.0] - 2026-04-09

### Added

- Initial release of Wave chart
