# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.5] - 2026-06-24

### Added

- Add ArtifactHub annotations: license, links, and sign key.

## [1.4.4] - 2026-06-11

### Added

- Add chart icon.
- Auto-infer types for JSON schema values file.

## [1.4.3] - 2026-06-10

### Added

- Include Helm values JSON schema.

## [1.4.2] - 2026-06-01

### Changed

- Bump bitnami/common dependency to 2.40.0.

## [1.4.1] - 2026-05-13

### Changed

- Update Studios container image paths to `cr.seqera.io/enterprise/studios/{server,proxy}`.

## [1.4.0] - 2026-05-13

### Changed

- Bump application version to 0.11.1.
- Update connect client images to 0.12, deprecating 0.11.

## [1.3.1] - 2026-05-12

### Changed

- Update image paths in the README and values.yaml - the chart does not hardcode `cr.seqera.io` as the registry, customers are invited to vendor the images to their private registry as well as the charts.

## [1.3.0] - 2026-05-05

- **Enhancement**: allow global configuration of Ingress options. A new `global.ingress` block (`enabled`, `path`, `defaultPathType`, `ingressClassName`, `annotations`, `extraLabels`, `tls`) lets cluster-wide Ingress defaults be set once at the parent and propagate to every subchart, removing the need to repeat controller-wide config per subchart. `enabled` is OR-merged; scalar fields fall back to global when local is unset; `annotations` and `extraLabels` are merged with local winning on key collision; `tls` is concatenated (useful for a single wildcard certificate across all services).
- Add `seqera.ingress.host` template helper in each chart's `_helpers.tpl` returning that chart's primary domain. Lets users write `external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'` once in `global.ingress.annotations` and have it resolve to the correct host per chart at render time, without hard-coding hostnames.
- Add `docs/conventions/ingress.md` documenting the Ingress conventions used across charts.

### Changed

- Update bitnami/common to 2.39.0
- **BREAKING**: Default `ingress.defaultPathType` is now `Prefix` (was `ImplementationSpecific`). With the previous default and the chart's default `path: "/"`, routing behavior depended on the ingress controller — NGINX treated it as a prefix match, AWS ALB required `/*` for the same effect, GKE applied its own interpretation. The result was the same chart and values producing different routing across clusters. `Prefix` is part of the Kubernetes Ingress spec and produces consistent prefix-match semantics across NGINX, Traefik, AWS ALB, and most modern controllers, giving users a predictable out-of-the-box experience. Users whose controller still requires `ImplementationSpecific` (e.g. older GKE) can set `global.ingress.defaultPathType: ImplementationSpecific` once at the parent.

## [1.2.15] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.2 (Redis init container log message now reports `auth set` or `auth not set`)

## [1.2.14] - 2026-04-30

### Changed

- Clear the default values for `global.platformServiceAddress` and `global.platformServicePort` so they must be explicitly set when deploying this subchart standalone. They point to the Seqera Platform backend service. When deploying as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section
- Improve `NOTES.txt` validation messages for `global.platformServiceAddress` and `global.platformServicePort` to clarify that these values are inherited from the parent `platform` umbrella chart
- Document the Platform Service connection details as a required configuration in the README

## [1.2.13] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.1 (Redis init container no longer logs the password)

## [1.2.12] - 2026-04-29

### Fixed

- Fixed default key for external OIDC secret to use `CONNECT_OIDC_CLIENT_REGISTRATION_TOKEN`, consistent with the key used in the chart-managed secret

## [1.2.11] - 2026-04-28

### Added

- Write `CONNECT_OIDC_CLIENT_REGISTRATION_TOKEN` to the chart-managed secret when `proxy.oidcClientRegistrationToken` is set as a string, enabling standalone deployments without an external secret
- Require either `proxy.oidcClientRegistrationToken` or `proxy.oidcClientRegistrationTokenSecretName` to be set at install/upgrade time

## [1.2.10] - 2026-04-10

### Changed

- Bump `seqera-common` dependency to 2.1.0

## [1.2.9] - 2026-04-08

### Changed

- Fixed changelog

## [1.2.8] - 2026-04-08

### Changed

- Bumped seqera-common to 2.0.2

## [1.2.7] - 2026-04-07

### Added

- Add `extraEnv` and `extraVolumeMounts` to `initContainerDependencies.waitForPlatform` values, enabling CA certificate mounts and additional env vars in the wait init container

### Changed

- User-supplied `initContainers` now render before built-in `waitFor*` init containers, enabling cert-fetching sidecars to run before dependency checks

## [1.2.6] - 2026-03-31

### Changed

- Bumped bitnami/common dependency to 2.38.0

## [1.2.5] - 2026-03-31

### Changed

- Update documentation warning about Helm-generated random values with Kustomize

## [1.2.4] - 2026-03-25

### Changed

- Update studios default subdomain to studios.

## [1.2.3] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [1.2.2] - 2026-03-18

### Changed

- Restructured OIDC initial access token functions into Platform chart

## [1.2.1] - 2026-02-20

### Changed

- Bumped app version to 0.11.0 to include latest bug fixes and improvements in Studios application
- Updated chart version to 1.2.1 to reflect app version update

## [1.2.0] - 2026-02-20

### Added

- Support for cloud-provider-specific image overrides via `global.azure.images` for all container images (proxy, server, wait-for-platform)
- Updated seqera-common to version 2.0.0

## [1.1.5] - 2026-02-10

### Changed

- Re-release to trigger build after GitHub Actions outage

## [1.1.4] - 2026-02-09

### Fixed

- Fixed ingress template to properly handle port numbers when provided as integers, string integers, or template expressions by adding `tpl (toString ...)` conversion
- Fixed service template to properly handle port and targetPort values when provided as integers, string integers, or template expressions

### Added

- Added comprehensive unit tests for ingress port number handling with different input types (integer, string integer, template string)

## [1.1.3] - 2026-01-30

### Changed

- Updated environment variable rendering to use `seqera.envVars.render` helper function instead of `seqera.tplvalues.render` for correct templating behavior

## [1.1.2] - 2026-01-30

### Changed

- Optimized unit tests for faster execution

## [1.1.1] - 2026-01-23

### Changed

- Added warning in `values.yaml` about Kustomize incompatibility with Helm auto-generated random values

## [1.1.0] - 2026-01-23

### Changed

- Updated Studios application version to 0.9.0

## [1.0.1] - 2026-01-15

### Added

- Added `global.imageCredentialsSecrets` configuration to support multiple pre-existing image pull secrets
  - Allows referencing existing Kubernetes secrets of type `kubernetes.io/dockerconfigjson` for private registry authentication
  - Secrets are automatically added to the ServiceAccount's `imagePullSecrets` list
  - Complements existing `global.imageCredentials` for inline secret creation

### Changed

- Changed default replica counts to 2 to improve high availability
- Updated OIDC token secret management to recreate token if missing from secret
  - Addresses scenario where Studios is enabled after initial Platform installation
- Removed component-specific labels and annotations from ConfigMap values
  - Made `commonLabels` and `commonAnnotations` more generic and reusable

### Fixed

- Fixed `studios.redis.secretKey` and `studios.oidcToken.secretKey` helpers to ignore custom `existingSecretKey` when using chart-managed secrets
- Fixed Redis environment variable mount in server StatefulSet
- Fixed `CONNECT_LOG_LEVEL` environment variable name in ConfigMap (was using incorrect variable name)

## [1.0.0] - 2026-01-13

### Added

- Initial release of Studios chart
- Helm chart for deploying Seqera Studios service (interactive analysis platform)
- Deployment templates:
  - StatefulSet for Studios server component with persistent storage
  - Deployment for Studios proxy component
- Service configuration for both server and proxy components
- Ingress support for external access
- ConfigMap for Studios configuration
- Secret management for sensitive data (OIDC tokens, encryption keys)
- ServiceAccount with configurable annotations for cloud provider integration
- Support for extra resources deployment via `extraDeploy`
- Integration with Seqera Platform as a dependency
  - Init container to wait for Platform readiness using `seqera-common` library
  - Platform URL configuration and validation
- Comprehensive test suite with 100% coverage:
  - Unit tests for all templates
  - Snapshot tests for resource validation
  - Platform URL integration tests
- Dependencies:
  - `seqera-common` library chart for shared helpers
  - Bitnami `common` library for standard helpers
