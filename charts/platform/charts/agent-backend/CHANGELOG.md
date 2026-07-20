# Changelog

All notable changes to this chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added Gateway API support via a new `httpRoute.*` (and `global.httpRoute.*`) values block. When
  `httpRoute.enabled` is `true`, the chart renders `HTTPRoute` objects
  (`gateway.networking.k8s.io/v1`) that attach to an existing Gateway via `httpRoute.parentRefs`,
  as an alternative to `ingress` (the two are independent toggles). TLS is terminated on the
  Gateway listener; the chart does not create the Gateway or GatewayClass.
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

## [1.1.0] - 2026-07-07

### Changed

- Added `examples/standalone.yaml` with a minimal values file for deploying this chart independently.
- Bumped `appVersion` to `1.13.1`.
- Refresh deployment snapshot after `platformServiceAddress` requirement (#131).
- Annotated `values.yaml` with `# @section` markers and switched `README.md.gotmpl` to a per-section Markdown loop, grouping the generated values table by area instead of one flat list.
- Revamp README documentation.

### Removed

- **BREAKING**: Removed `global.azure.images` image overrides for `agentBackend` and the
  `waitForMySQL`/`waitForRedis` init containers. Deployments now resolve images through
  `common.images.image` only.
- Bumped `seqera-common` dependency to `3.x.x`.

## [1.0.9] - 2026-06-24

### Added

- Add ArtifactHub annotations: license, links, and sign key.

## [1.0.8] - 2026-06-11

### Added

- Add chart icon.
- Auto-infer types for JSON schema values file.

## [1.0.7] - 2026-06-10

### Added

- Include Helm values JSON schema.

## [1.0.6] - 2026-06-02

### Fixed

- Do not inject `ANTHROPIC_API_KEY` env var in the Deployment when `anthropic.apiKey` is empty and no `existingSecretName` is set, preventing a pod startup failure when using the bedrock provider.

## [1.0.5] - 2026-06-01

### Changed

- Bump bitnami/common dependency to 2.40.0.

## [1.0.4] - 2026-05-29

### Fixed

- Do not render `ANTHROPIC_API_KEY` in the Secret when `anthropic.apiKey` is empty and no `existingSecretName` is set.

## [1.0.3] - 2026-05-22

### Changed

- Updated agent-backend application version to 1.11.0

## [1.0.2] - 2026-05-15

### Changed

- Rename `redis.db` to `redis.database` for consistency with other charts. The old `redis.db` key is still accepted as a fallback.

## [1.0.1] - 2026-05-14

### Changed

- Update agent-backend application version to 1.10.0.

## [1.0.0] - 2026-05-11

### Added

- Add link to [Seqera AI prerequisites](https://docs.seqera.io/platform-enterprise/seqera-ai/prerequisites) documentation in the README.

### Changed

- **BREAKING**: Redesign provider configuration to support multiple LLM providers. The flat Bedrock-only
  values have been replaced with a structured `inference` / `embeddings` / `sandbox` routing layer and
  per-provider configuration blocks (`bedrock`, `anthropic`). Operators must now declare which provider
  serves each capability. See migration table below.

  | Old key                              | New key                                  |
  |--------------------------------------|------------------------------------------|
  | `bedrockAgentCoreArn`                | `bedrock.sandbox.runtimeArn`             |
  | `bedrockAssumeRoleArn`               | `bedrock.default.assumeRoleArn`          |
  | `bedrockAnthropicModel`              | `bedrock.inference.anthropicModel`       |
  | `embeddings.bedrock.region`          | `bedrock.embeddings.region`              |
  | `embeddings.bedrock.modelId`         | `bedrock.embeddings.model`               |
  | `embeddings.bedrock.dimensions`      | _(removed — see below)_                  |
  | `anthropicApiKey`                    | `anthropic.apiKey`                       |
  | `anthropicApiKeyExistingSecretName`  | `anthropic.existingSecretName`           |
  | `anthropicApiKeyExistingSecretKey`   | `anthropic.existingSecretKey`            |
  | _(was hardcoded `true`)_             | `inference.provider: bedrock`            |
  | _(was hardcoded `"bedrock"`)_        | `embeddings.provider: bedrock`           |
  | _(was implicit)_                     | `sandbox.provider: bedrock`              |

- **BREAKING**: Remove `bedrock.embeddings.dimensions` value and `NEXTFLOW_DOCS_BEDROCK_DIMENSIONS` env var: the application provides a good default.
- Remove redundant Anthropic API key validation from `NOTES.txt`; fully covered by `validateProviders` in `_helpers.tpl`.
- Add validator: `sandbox.provider: bedrock` now requires `bedrock.sandbox.runtimeArn` to be set.
- Replace deprecated `NEXTFLOW_DOCS_USE_REDIS_INDEX` env var with `NEXTFLOW_DOCS_TOOL` (`memory` when `embeddings.provider` is set, `disabled` otherwise). Remove `nextflowDocs.useRedisIndex` value.
- Update image paths in the README and values.yaml - the chart does not hardcode `cr.seqera.io` as the registry, customers are invited to vendor the images to their private registry as well as the charts.

## [0.5.0] - 2026-05-05

- **Enhancement**: allow global configuration of Ingress options. A new `global.ingress` block (`enabled`, `path`, `defaultPathType`, `ingressClassName`, `annotations`, `extraLabels`, `tls`) lets cluster-wide Ingress defaults be set once at the parent and propagate to every subchart, removing the need to repeat controller-wide config per subchart. `enabled` is OR-merged; scalar fields fall back to global when local is unset; `annotations` and `extraLabels` are merged with local winning on key collision; `tls` is concatenated (useful for a single wildcard certificate across all services).
- Add `seqera.ingress.host` template helper in each chart's `_helpers.tpl` returning that chart's primary domain. Lets users write `external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'` once in `global.ingress.annotations` and have it resolve to the correct host per chart at render time, without hard-coding hostnames.
- Add `docs/conventions/ingress.md` documenting the Ingress conventions used across charts.

### Changed

- Update bitnami/common to 2.39.0
- **BREAKING**: Default `ingress.defaultPathType` is now `Prefix` (was `ImplementationSpecific`). With the previous default and the chart's default `path: "/"`, routing behavior depended on the ingress controller — NGINX treated it as a prefix match, AWS ALB required `/*` for the same effect, GKE applied its own interpretation. The result was the same chart and values producing different routing across clusters. `Prefix` is part of the Kubernetes Ingress spec and produces consistent prefix-match semantics across NGINX, Traefik, AWS ALB, and most modern controllers, giving users a predictable out-of-the-box experience. Users whose controller still requires `ImplementationSpecific` (e.g. older GKE) can set `global.ingress.defaultPathType: ImplementationSpecific` once at the parent.

## [0.4.11] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.2 (Redis init container log message now reports `auth set` or `auth not set`)

## [0.4.10] - 2026-04-30

### Changed

- Clear the default values for `global.platformServiceAddress` and `global.platformServicePort` so they must be explicitly set when deploying this subchart standalone. They point to the Seqera Platform backend service. When deploying as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section
- Add `NOTES.txt` validation that fails the installation when `global.platformServiceAddress` or `global.platformServicePort` are not set
- Document the Platform Service connection details as a required configuration in the README

## [0.4.9] - 2026-04-30

### Changed

- Bump `seqera-common` dependency to 2.1.1 (Redis init container no longer logs the password)

## [0.4.8] - 2026-04-29

### Changed

- Point `SEQERA_PLATFORM_API_URL` to the internal Platform backend service (`platformServiceAddress`:`platformServicePort`) instead of the external domain

### Added

- Add `SEQERA_PLATFORM_URL` env var pointing to the external platform URL for use in links and callbacks from the agent backend
- Add `global.platformServiceAddress` and `global.platformServicePort` values
- Add `KNOWLEDGE_INDEXER_EMBEDDINGS_PROVIDER` env var set to `bedrock`
- Add `nextflowDocs.useRedisIndex` value to control `NEXTFLOW_DOCS_USE_REDIS_INDEX` (defaults to `false`)
- Add `bedrockAssumeRoleArn` value to optionally set `AWS_BEDROCK_SERVICES_DEFAULT_ASSUME_ROLE_ARN` for cross-account Bedrock access
- Add `bedrockAnthropicModel` value to optionally override `BEDROCK_ANTHROPIC_MODEL`

## [0.4.7] - 2026-04-20

### Added

- Add first-class Bedrock embedding configuration values under `.embeddings`
- Add explicit `bedrockAgentCoreArn` value and render `AGENTCORE_AGENT_ARN` into the chart configmap when configured

## [0.4.6] - 2026-04-10

### Changed

- Reorder `values.yaml` sections to group `redis` alongside `database` for better readability
- Update README to mention Redis connection details as a required configuration
- Bump `seqera-common` dependency to 2.1.0

## [0.4.5] - 2026-04-08

### Changed

- Fixed changelog

## [0.4.4] - 2026-04-08

### Changed

- Add tests covering `REDISCLI_TLS` env var presence on the wait-for-redis init container based on `redis.enableTls` value

## [0.4.3] - 2026-04-07

### Added

- Add TLS options for the database connection: `database.enableTls`, `database.tlsCaVerify`, and `database.sslCa` values to configure TLS, CA verification, and CA certificate path

### Changed

- Add tests covering `REDISCLI_TLS` env var presence on the wait-for-redis init container based on `redis.enableTls` value

## [0.4.2] - 2026-04-07

### Added

- Add `extraEnv` and `extraVolumeMounts` to `initContainerDependencies.waitForMySQL` and `initContainerDependencies.waitForRedis` values, enabling CA certificate mounts and additional env vars in wait init containers
- `MYSQL_EXTRA_ARGS` example documented under `waitForMySQL.extraEnv` for passing TLS flags such as `--ssl-ca` and `--ssl-mode`
- Bumped seqera-common to 2.0.1

### Changed

- User-supplied `initContainers` now render before built-in `waitFor*` init containers, enabling cert-fetching sidecars to run before dependency checks

## [0.4.1] - 2026-03-31

### Changed

- Bumped bitnami/common dependency to 2.38.0
- **BREAKING** Rename `redis.tls` value to `redis.enableTls`

## [0.3.1] - 2026-03-31

### Changed

- Update documentation warning about Helm-generated random values with Kustomize

## [0.3.0] - 2026-03-26

### Added

- Add Redis support: new `redis` configuration block with `host`, `port`, `db`, `tls`, `password`, `existingSecretName`, and `existingSecretKey` values

## [0.2.8] - 2026-03-25

### Changed

- Remove mention of Langchain as requirement from Readme, removed in 0.2.3..0.2.5

## [0.2.7] - 2026-03-23

### Changed

- Bumped bitnami/common dependency to 2.37.0

## [0.2.6] - 2026-03-19

### Changed

- Auto-generate a valid Fernet-compatible token encryption key (URL-safe base64 of 32 random bytes) when `tokenEncryptionKey` is not provided, instead of falling back to a random alphanumeric password

## [0.2.5] - 2026-03-12

### Changed

- Removing validation for optional langchainApiKey

## [0.2.4] - 2026-03-12

### Changed

- Removing optional secrets from chart - as they will be added with extraEnvVars at deployment time

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
