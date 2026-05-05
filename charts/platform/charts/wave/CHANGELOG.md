# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Refresh deployment snapshot after `platformServiceAddress` requirement (#131).

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
