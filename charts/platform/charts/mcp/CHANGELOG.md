# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-07-07

### Changed

- Added `examples/standalone.yaml` with a minimal values file for deploying this chart independently.
- Bumped `appVersion` to `1.4.2`.
- Bumped `seqera-common` dependency to `3.x.x`. The `waitForPlatform` init container no longer
  accepts a `cloudProviderImageKey` — `global.azure.images` overrides are no longer honored.

## [0.4.6] - 2026-07-07

### Changed

- Revamp README documentation.

## [0.4.5] - 2026-06-24

### Added

- Add ArtifactHub annotations: license, links, and sign key.

## [0.4.4] - 2026-06-11

### Added

- Add chart icon.
- Auto-infer types for JSON schema values file.

## [0.4.3] - 2026-06-10

### Added

- Include Helm values JSON schema.

## [0.4.2] - 2026-06-01

### Changed

- Bump bitnami/common dependency to 2.40.0.

## [0.4.1] - 2026-05-11

### Added

- Add link to [Seqera AI prerequisites](https://docs.seqera.io/platform-enterprise/seqera-ai/prerequisites) documentation in the README.

### Changed

- Bump appVersion to 1.3.0.
- Update image paths in the README and values.yaml - the chart does not hardcode `cr.seqera.io` as the registry, customers are invited to vendor the images to their private registry as well as the charts.
- `TOWER_API_ENDPOINT` now uses the internal platform service address and port (`global.platformServiceAddress`/`global.platformServicePort`) instead of the external domain, so MCP communicates with the platform over the cluster-internal network, skipping the ingress layer and removing traffic from the platform frontend container.

## [0.4.0] - 2026-05-05

- **Enhancement**: allow global configuration of Ingress options. A new `global.ingress` block (`enabled`, `path`, `defaultPathType`, `ingressClassName`, `annotations`, `extraLabels`, `tls`) lets cluster-wide Ingress defaults be set once at the parent and propagate to every subchart, removing the need to repeat controller-wide config per subchart. `enabled` is OR-merged; scalar fields fall back to global when local is unset; `annotations` and `extraLabels` are merged with local winning on key collision; `tls` is concatenated (useful for a single wildcard certificate across all services).
- Add `seqera.ingress.host` template helper in each chart's `_helpers.tpl` returning that chart's primary domain. Lets users write `external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'` once in `global.ingress.annotations` and have it resolve to the correct host per chart at render time, without hard-coding hostnames.
- Add `docs/conventions/ingress.md` documenting the Ingress conventions used across charts.

### Changed

- Update bitnami/common to 2.39.0
- **BREAKING**: Default `ingress.defaultPathType` is now `Prefix` (was `ImplementationSpecific`). With the previous default and the chart's default `path: "/"`, routing behavior depended on the ingress controller — NGINX treated it as a prefix match, AWS ALB required `/*` for the same effect, GKE applied its own interpretation. The result was the same chart and values producing different routing across clusters. `Prefix` is part of the Kubernetes Ingress spec and produces consistent prefix-match semantics across NGINX, Traefik, AWS ALB, and most modern controllers, giving users a predictable out-of-the-box experience. Users whose controller still requires `ImplementationSpecific` (e.g. older GKE) can set `global.ingress.defaultPathType: ImplementationSpecific` once at the parent.

## [0.3.6] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.2 (Redis init container log message now reports `auth set` or `auth not set`)

## [0.3.5] - 2026-04-30

### Changed

- Clear the default values for `global.platformServiceAddress` and `global.platformServicePort` so they must be explicitly set when deploying this subchart standalone. They point to the Seqera Platform backend service. When deploying as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section
- Add `NOTES.txt` validation that fails the installation when `global.platformServiceAddress` or `global.platformServicePort` are not set
- Document the Platform Service connection details as a required configuration in the README

## [0.3.4] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.1 (Redis init container no longer logs the password)

## [0.3.3] - 2026-04-29

### Fixed

- Fixed default key for external OIDC secret to use `MCP_OAUTH_INITIAL_ACCESS_TOKEN`, consistent with the key used in the chart-managed secret

## [0.3.2] - 2026-04-28

### Fixed

- Fixed the name of the oauth initial access token variable in the helper script
- Made oauth initial access token a requirement for the MCP chart

## [0.3.1] - 2026-04-10

### Changed

- Bump `seqera-common` dependency to 2.1.0

## [0.3.0] - 2026-04-09

### Changed

- **BREAKING** Rename environment variables to use `MCP_` prefix: `TOWER_OIDC_REGISTRATION_INITIAL_ACCESS_TOKEN` → `MCP_OAUTH_INITIAL_ACCESS_TOKEN`, `OAUTH_JWT_SECRET` → `MCP_OAUTH_JWT_SECRET`, `OAUTH_ISSUER_URL` → `MCP_OAUTH_ISSUER_URL`, `OAUTH_AUDIENCE` → `MCP_OAUTH_AUDIENCE`
- When upgrading from 0.2.x, you may encounter errors such as `PASSWORDS ERROR: The secret "releasename-mcp" does not contain the key "MCP_OAUTH_JWT_SECRET"`. To resolve this, you can run the following command to update the secret with the new key:
  ```
  kubectl -n <namespace> get secret releasename-mcp -o yaml |
    sed 's/OAUTH_JWT_SECRET/MCP_OAUTH_JWT_SECRET/g' |
    kubectl apply -f -
  ```
- Bump appVersion to 1.1.0

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
