# platform

A Helm chart to deploy Seqera Platform (also referred to as Tower) on Kubernetes.

![Version: 0.25.3](https://img.shields.io/badge/Version-0.25.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.0](https://img.shields.io/badge/AppVersion-v25.3.0-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

For an overview of the Seqera Platform architecture and its requirements, refer to the [Seqera documentation](https://docs.seqera.io/platform-enterprise/enterprise/overview).

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- The `.image` section under the `.backend`, `.frontend`, `.cron` and `.cron.dbMigrationInitContainer` components to point to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for `cr.seqera.io` or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.
- The database connection details for the Platform MySQL database under the `.platformDatabase` section.
- The redis connection details under the `.redis` section.
- The Seqera license key under the `.platform.licenseString` value, or the name of an existing Secret containing the license key under the `.platform.licenseSecretName` value.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `v25.3.0`.

> [!NOTE]
> The Platform chart requires the [unprivileged version](https://docs.seqera.io/platform-enterprise/enterprise/kubernetes#seqera-frontend-unprivileged) of the Seqera Platform frontend image (shipped with `-unprivileged` suffix until Platform v25.3, without any suffix starting from v26.1).

When a sensitive value is required (e.g. the database password, the Seqera license key), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is used instead, the chart instructs the components to read the sensitive value from the external Secret directly, without storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/platform \
  --version 0.25.3 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/platform

## Examples

Refer to the [examples directory](./examples) for different scenarios of installing the Platform chart.
The examples provided are showcasing possible configurations of the Helm chart, and are not representative of a full installation.
Please refer to the [Seqera Platform documentation](https://docs.seqera.io/platform-enterprise/enterprise/overview) for complete installation instructions.

## Upgrading the chart

When upgrading between versions, please refer to the [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration instructions.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../seqera-common | seqera-common | 1.x.x |
| file://charts/pipeline-optimization | pipeline-optimization | 0.2.x |
| file://charts/studios | studios | 1.x.x |
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platformExternalDomain | string | `"example.com"` | Domain where Seqera Platform listens |
| global.contentDomain | string | `"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"` | Domain where user-created Platform reports are exposed, to avoid Cross-Site Scripting (XSS) attacks. If unset, data is served through the main domain `.global.platformExternalDomain`. Evaluated as a template |
| global.platformServiceAddress | string | `"{{ printf \"%s-platform-backend\" .Release.Name | lower }}"` | Seqera Platform Service name: can be the internal Kubernetes hostname or an external ingress hostname. Evaluated as a template |
| global.platformServicePort | int | `8080` | Seqera Platform Service port |
| global.studiosDomain | string | `"{{ printf \"studios.%s\" .Values.global.platformExternalDomain }}"` | Domain where the Studios service listens. Make sure the TLS certificate covers this and its wildcard subdomains. Evaluated as a template |
| global.studiosConnectionUrl | string | `"{{ printf \"https://connect.%s\" (tpl .Values.global.studiosDomain $) }}"` | Base URL for Studios connections: can be any value, since each session will use a unique subdomain under `.global.studiosDomain` anyway to connect. Evaluated as a template |
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| global.imageCredentialsSecrets | list | `[]` | Optional list of existing Secrets containing image pull credentials to use for pulling images from private registries. These Secrets are shared with all the subcharts automatically |
| platformDatabase.host | string | `""` | Platform MySQL database hostname |
| platformDatabase.port | int | `3306` | Platform MySQL database port |
| platformDatabase.name | string | `""` | Platform MySQL database name |
| platformDatabase.username | string | `""` | Platform MySQL database username |
| platformDatabase.password | string | `""` | Platform MySQL database password |
| platformDatabase.existingSecretName | string | `""` | Name of an existing Secret containing credentials for the Platform MySQL database, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platformDatabase.existingSecretKey | string | `"TOWER_DB_PASSWORD"` | Key in the existing Secret containing the password for the Platform MySQL database |
| platformDatabase.driver | string | `"mariadb"` | Database driver. Possible options: "mariadb" (or its alias "mysql") |
| platformDatabase.connectionOptions | object | `{"mariadb":["permitMysqlScheme=true"]}` | Connection options to compose in the driver URL according to the driver used. The only driver that can be set is 'mariadb' |
| platformDatabase.connectionOptions.mariadb | list | `["permitMysqlScheme=true"]` | Connection options to use with the MariaDB driver. For the full list of supported options see: https://mariadb.com/docs/connectors/mariadb-connector-j/about-mariadb-connector-j |
| platformDatabase.dialect | string | `"mysql-8"` | Hibernate dialect to use, depending on the database version. Possible options: mysql-8 (default), mariadb-10 |
| platformDatabase.minPoolSize | string | `"2"` | Connection pool minimum size |
| platformDatabase.maxPoolSize | string | `"10"` | Connection pool maximum size |
| platformDatabase.maxLifetime | string | `"180000"` | Connection pool maximum lifetime |
| platform.YAMLConfigFileContent | string | `""` | Content to insert into the tower.yml file (you can use `\|-` YAML multilines). See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview |
| platform.contactEmail | string | `"support@example.com"` | Sender email address for user support |
| platform.jwtSeedString | string | `""` | JWT seed, defined as string, used to sign authentication tokens. Define the value as a String or a Secret, not both at the same time. If neither is defined, Helm generates a random 35-character string. WARNING: Auto-generated random values are incompatible with Kustomize. When upgrading releases via Kustomize, Helm cannot query the cluster to check if a secret already exists, causing it to regenerate a new random value on each upgrade, which will break authentication. Always explicitly set this value or use an existing secret when using Kustomize |
| platform.jwtSeedSecretName | string | `""` | Name of an existing Secret containing the JWT seed, as an alternative to the string field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platform.jwtSeedSecretKey | string | `"TOWER_JWT_SECRET"` | Key in the existing Secret containing the JWT seed |
| platform.cryptoSeedString | string | `""` | Crypto seed, defined as string, used to encrypt sensitive data in the database. Note: this needs to be a stable value that doesn't change between deployments, otherwise encrypted data in the database will become inaccessible. Either define the value as a String or a Secret, not both at the same time. If neither is defined, a random 35 characters long string will be generated by Helm WARNING: Auto-generated random values are incompatible with Kustomize. When upgrading releases via Kustomize, Helm cannot query the cluster to check if a secret already exists, causing it to regenerate a new random value on each upgrade, which will make  existing encrypted data inaccessible. Always explicitly set this value or use an existing secret when using Kustomize |
| platform.cryptoSeedSecretName | string | `""` | Name of an existing Secret containing the crypto seed, as an alternative to the string field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platform.cryptoSeedSecretKey | string | `"TOWER_CRYPTO_SECRETKEY"` | Key in the existing Secret containing the crypto seed |
| platform.executionBackends | list | `["altair-platform","awsbatch-platform","awscloud-platform","azbatch-platform","azcloud-platform","eks-platform","gke-platform","googlebatch-platform","googlecloud-platform","k8s-platform","local-platform","lsf-platform","moab-platform","slurm-platform"]` | List of execution backends to enable. At least one is required. See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview#compute-environments |
| platform.licenseString | string | `""` | Platform license key. A license key is a long alphanumeric string provided by your Seqera account manager. Define the value as a String or a Secret, not both at the same time |
| platform.licenseSecretName | string | `""` | Name of an existing Secret containing the Platform license key, as an alternative to the string field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platform.licenseSecretKey | string | `"TOWER_LICENSE"` | Key in the existing Secret containing the Platform license key |
| platform.oidcPrivateKeyBase64 | string | `""` | OIDC private key in PEM format, base64-encoded. Define the value as a String or a Secret, not both at the same time. If neither is defined, Helm generates a random private key. WARNING: Auto-generated random values are incompatible with Kustomize. When upgrading releases via Kustomize, Helm cannot query the cluster to check if a secret already exists, causing it to regenerate a new random value on each upgrade, which may break existing OIDC sessions. Always explicitly set this value or use an existing secret when using Kustomize |
| platform.oidcPrivateKeySecretName | string | `""` | Name of an existing Secret containing the OIDC private key in PEM format, as an alternative to the base64-encoded string field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platform.oidcPrivateKeySecretKey | string | `"oidc.pem"` | Key in the existing Secret containing the OIDC private key in PEM format |
| platform.smtp.host | string | `""` | SMTP server hostname to let users authenticate through email, and to send email notifications for events |
| platform.smtp.port | string | `""` | SMTP server port |
| platform.smtp.user | string | `""` | SMTP server username |
| platform.smtp.password | string | `""` | SMTP server password |
| platform.smtp.existingSecretName | string | `""` | Name of an existing secret containing the SMTP password |
| platform.smtp.existingSecretKey | string | `"TOWER_SMTP_PASSWORD"` | Key in the existing Secret containing the SMTP password |
| platform.waveServerUrl | string | `"https://wave.seqera.io"` | URL of the Wave service Platform uses. Evaluated as a template. The Wave service provided by Seqera is `https://wave.seqera.io` |
| platform.dataExplorer.enabled | bool | `false` | Enable the Data Explorer feature: https://docs.seqera.io/platform-enterprise/data/data-explorer |
| platform.studios.tools | object | `{"jupyter":{"deprecated":"public.cr.seqera.io/platform/data-studio-jupyter:4.1.5-0.7.1","recommended":"public.cr.seqera.io/platform/data-studio-jupyter:4.2.5-0.8","tool":"jupyter"},"rstudio":{"recommended":"public.cr.seqera.io/platform/data-studio-ride:2025.04.1-0.8","tool":"rstudio"},"vscode":{"deprecated":"public.cr.seqera.io/platform/data-studio-vscode:1.93.1-0.8","recommended":"public.cr.seqera.io/platform/data-studio-vscode:1.101.2-0.8","tool":"vscode"},"xpra":{"recommended":"public.cr.seqera.io/platform/data-studio-xpra:6.2.0-r2-1-0.8","tool":"xpra"}}` | Map of tools to make available in Studios. Recommended and deprecated versions can be specified for each tool to allow upgrading from an older version. Refer to the documentation for more details: https://docs.seqera.io/platform-enterprise/studios/managing#migrate-a-studio-from-an-earlier-container-image-template |
| platform.configMapLabels | object | `{}` | Additional labels for the ConfigMap objects. Evaluated as a template |
| platform.secretLabels | object | `{}` | Additional labels for the Secret objects. Evaluated as a template |
| platform.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| platform.configMapAnnotations | object | `{}` | Additional annotations for the ConfigMap objects. Evaluated as a template |
| platform.secretAnnotations | object | `{}` | Additional annotations for the Secret objects. Evaluated as a template |
| platform.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |
| redis.host | string | `""` | Redis hostname |
| redis.port | int | `6379` | Redis port |
| redis.password | string | `""` | Redis password if the installation requires it |
| redis.existingSecretName | string | `""` | Name of an existing Secret containing credentials for Redis, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| redis.existingSecretKey | string | `"TOWER_REDIS_PASSWORD"` | Key in the existing Secret containing the password for Redis |
| redis.enableTls | bool | `false` | Enable TLS when connecting to Redis |
| backend.image.registry | string | `""` | Backend container image registry |
| backend.image.repository | string | `"private/nf-tower-enterprise/backend"` | Backend container image repository |
| backend.image.tag | string | `"{{ .chart.AppVersion }}"` | Backend container image tag |
| backend.image.digest | string | `""` | Backend container image digest in the format `sha256:1234abcdef` |
| backend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the backend container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| backend.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| backend.micronautEnvironments | list | `["prod","redis","ha"]` | List of Micronaut Environments to enable on the backend pod |
| backend.service.type | string | `"ClusterIP"` | Backend Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| backend.service.http.name | string | `"http"` | Service name to use |
| backend.service.http.targetPort | int | `8080` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). Platform v25.3+ only; previous versions were hardcoded to 8080 |
| backend.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| backend.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| backend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| backend.initContainers | list | `[]` | Additional init containers for the backend pod. Evaluated as a template |
| backend.command | list | `[]` | Override default container command (useful when using custom images) |
| backend.args | list | `[]` | Override default container args (useful when using custom images) |
| backend.podLabels | object | `{}` | Additional labels for the backend pod. Evaluated as a template |
| backend.podAnnotations | object | `{}` | Additional annotations for the backend pod. Evaluated as a template |
| backend.extraOptionsSpec | object | `{"replicas":3}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| backend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |
| backend.extraEnvVars | list | `[]` | Extra environment variables to set on the backend pod |
| backend.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| backend.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| backend.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| backend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| backend.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| backend.podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| backend.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| backend.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| backend.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| backend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| backend.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| backend.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| backend.startupProbe.enabled | bool | `false` | Enable startup probe |
| backend.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe |
| backend.startupProbe.httpGet.port | string | `"{{ .Values.backend.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080 |
| backend.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| backend.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| backend.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| backend.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| backend.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| backend.readinessProbe.enabled | bool | `true` | Enable readiness probe |
| backend.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe |
| backend.readinessProbe.httpGet.port | string | `"{{ .Values.backend.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080 |
| backend.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| backend.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| backend.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| backend.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| backend.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| backend.livenessProbe.enabled | bool | `true` | Enable liveness probe |
| backend.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe |
| backend.livenessProbe.httpGet.port | string | `"{{ .Values.backend.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080 |
| backend.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| backend.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| backend.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| backend.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| backend.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| frontend.image.registry | string | `""` | Frontend container image registry |
| frontend.image.repository | string | `"private/nf-tower-enterprise/frontend"` | Frontend container image repository |
| frontend.image.tag | string | `"{{ .chart.AppVersion }}-unprivileged"` | Specify a tag to override the version defined in .Chart.appVersion |
| frontend.image.digest | string | `""` | Frontend container image digest in the format `sha256:1234abcdef` |
| frontend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the frontend container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| frontend.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| frontend.service.type | string | `"ClusterIP"` | Frontend Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| frontend.service.http.name | string | `"http"` | Service name to use |
| frontend.service.http.port | int | `80` | Service port |
| frontend.service.http.targetPort | int | `8083` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| frontend.service.http.nodePort | int | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| frontend.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| frontend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| frontend.initContainers | list | `[]` | Additional init containers for the frontend pod. Evaluated as a template |
| frontend.command | list | `[]` | Override default container command (useful when using custom images) |
| frontend.args | list | `[]` | Override default container args (useful when using custom images) |
| frontend.podLabels | object | `{}` | Additional labels for the frontend pod. Evaluated as a template |
| frontend.podAnnotations | object | `{}` | Additional annotations for the frontend pod. Evaluated as a template |
| frontend.extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. revisionHistoryLimit, etc). Evaluated as a template. Note: the cron deployment can only run a single replica and use Recreate strategy |
| frontend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy). Evaluated as a template |
| frontend.extraEnvVars | list | `[]` | Extra environment variables to set on the frontend pod |
| frontend.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| frontend.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| frontend.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| frontend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| frontend.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| frontend.podSecurityContext.fsGroup | int | `101` | GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access |
| frontend.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| frontend.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| frontend.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| frontend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| frontend.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| frontend.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| frontend.startupProbe.enabled | bool | `false` | Enable startup probe |
| frontend.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe |
| frontend.startupProbe.httpGet.port | string | `"{{ .Values.frontend.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template |
| frontend.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| frontend.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| frontend.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| frontend.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| frontend.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| frontend.readinessProbe.enabled | bool | `true` | Enable readiness probe |
| frontend.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe |
| frontend.readinessProbe.httpGet.port | string | `"{{ .Values.frontend.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template |
| frontend.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| frontend.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| frontend.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| frontend.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| frontend.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| frontend.livenessProbe.enabled | bool | `true` | Enable liveness probe |
| frontend.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe |
| frontend.livenessProbe.httpGet.port | string | `"{{ .Values.frontend.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template |
| frontend.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| frontend.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| frontend.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| frontend.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| frontend.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| cron.image.registry | string | `""` | Cron container image registry |
| cron.image.repository | string | `"private/nf-tower-enterprise/backend"` | Cron container image repository |
| cron.image.tag | string | `"{{ .chart.AppVersion }}"` | Cron container image tag |
| cron.image.digest | string | `""` | Cron container image digest in the format `sha256:1234abcdef` |
| cron.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the cron container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| cron.micronautEnvironments | list | `["prod","redis","cron"]` | List of Micronaut Environments to enable on the cron pod |
| cron.service.type | string | `"ClusterIP"` | Cron Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| cron.service.http.name | string | `"http"` | Service name to use |
| cron.service.http.port | int | `8080` | Service port |
| cron.service.http.targetPort | int | `8082` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| cron.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| cron.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| cron.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| cron.initContainers | list | `[]` | Additional init containers for the cron pod. Evaluated as a template |
| cron.command | list | `[]` | Override default container command (useful when using custom images) |
| cron.args | list | `[]` | Override default container args (useful when using custom images) |
| cron.podLabels | object | `{}` | Additional labels for the cron pod. Evaluated as a template |
| cron.podAnnotations | object | `{}` | Additional annotations for the cron pod. Evaluated as a template |
| cron.extraOptionsSpec | object | `{}` | Extra options to place under .spec (for example, revisionHistoryLimit). Evaluated as a template Note that cron deployment needs to have a single replica with Recreate strategy |
| cron.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy) Evaluated as a template |
| cron.extraEnvVars | list | `[]` | Extra environment variables to set on the cron pod |
| cron.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| cron.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| cron.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| cron.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| cron.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| cron.podSecurityContext.fsGroup | int | `101` | GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access |
| cron.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| cron.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| cron.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| cron.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| cron.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| cron.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| cron.startupProbe.enabled | bool | `false` | Enable startup probe |
| cron.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe |
| cron.startupProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template |
| cron.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| cron.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| cron.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| cron.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| cron.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| cron.readinessProbe.enabled | bool | `true` | Enable readiness probe |
| cron.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe |
| cron.readinessProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template |
| cron.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| cron.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| cron.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| cron.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| cron.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| cron.livenessProbe.enabled | bool | `true` | Enable liveness probe |
| cron.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe |
| cron.livenessProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template |
| cron.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| cron.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| cron.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| cron.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| cron.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| cron.dbMigrationInitContainer.image.registry | string | `""` | Database migration container image registry |
| cron.dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/migrate-db"` | Database migration container image repository |
| cron.dbMigrationInitContainer.image.tag | string | `"{{ .chart.AppVersion }}"` | Specify a tag to override the version defined in .Chart.appVersion |
| cron.dbMigrationInitContainer.image.digest | string | `""` | Database migration container image digest in the format `sha256:1234abcdef` |
| cron.dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the database migration init container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.dbMigrationInitContainer.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| cron.dbMigrationInitContainer.command | list | `["/bin/sh","-c","/migrate-db.sh"]` | Override default container command (useful when using custom images) |
| cron.dbMigrationInitContainer.args | list | `[]` | Override default container args (useful when using custom images) |
| cron.dbMigrationInitContainer.extraEnvVars | list | `[]` | Extra environment variables to set on the cron pod |
| cron.dbMigrationInitContainer.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| cron.dbMigrationInitContainer.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| cron.dbMigrationInitContainer.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| cron.dbMigrationInitContainer.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| cron.dbMigrationInitContainer.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| cron.dbMigrationInitContainer.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| cron.dbMigrationInitContainer.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| cron.dbMigrationInitContainer.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies between Platform components (for example, wait for database readiness before cron starts, wait for cron before backend starts, etc) |
| initContainerDependencies.waitForMySQL.enabled | bool | `true` | Enable wait for MySQL init container before starting backend and cron |
| initContainerDependencies.waitForMySQL.image.registry | string | `""` | Override default wait for MySQL init container image |
| initContainerDependencies.waitForMySQL.image.repository | string | `"mysql"` |  |
| initContainerDependencies.waitForMySQL.image.tag | string | `"9"` |  |
| initContainerDependencies.waitForMySQL.image.digest | string | `""` |  |
| initContainerDependencies.waitForMySQL.image.pullPolicy | string | `"IfNotPresent"` |  |
| initContainerDependencies.waitForMySQL.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| initContainerDependencies.waitForMySQL.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| initContainerDependencies.waitForMySQL.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| initContainerDependencies.waitForMySQL.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| initContainerDependencies.waitForMySQL.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.5","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| initContainerDependencies.waitForRedis.enabled | bool | `true` | Enable wait for Redis init container before starting backend and cron |
| initContainerDependencies.waitForRedis.image.registry | string | `""` | Override default wait for Redis init container image |
| initContainerDependencies.waitForRedis.image.repository | string | `"redis"` |  |
| initContainerDependencies.waitForRedis.image.tag | string | `"7"` |  |
| initContainerDependencies.waitForRedis.image.digest | string | `""` |  |
| initContainerDependencies.waitForRedis.image.pullPolicy | string | `"IfNotPresent"` |  |
| initContainerDependencies.waitForRedis.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| initContainerDependencies.waitForRedis.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| initContainerDependencies.waitForRedis.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| initContainerDependencies.waitForRedis.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| initContainerDependencies.waitForRedis.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.5","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| initContainerDependencies.waitForCron.enabled | bool | `true` | Enable wait for Platform cron init container before starting backend |
| initContainerDependencies.waitForCron.image.registry | string | `""` | Override default wait for cron init container image |
| initContainerDependencies.waitForCron.image.repository | string | `"curlimages/curl"` |  |
| initContainerDependencies.waitForCron.image.tag | string | `"latest"` |  |
| initContainerDependencies.waitForCron.image.digest | string | `""` |  |
| initContainerDependencies.waitForCron.image.pullPolicy | string | `"IfNotPresent"` |  |
| initContainerDependencies.waitForCron.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| initContainerDependencies.waitForCron.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| initContainerDependencies.waitForCron.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| initContainerDependencies.waitForCron.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| initContainerDependencies.waitForCron.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.5","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| serviceAccount.name | string | `""` | Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated based on the release name |
| serviceAccount.annotations | object | `{}` | Additional annotations for the ServiceAccount to generate |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `false` | Automount service account token when the service account is generated |
| ingress.enabled | bool | `false` | Enable ingress for Platform |
| ingress.path | string | `"/"` | Path for the main ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller |
| ingress.contentPath | string | `"/"` | Path for the content domain ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller |
| ingress.defaultPathType | string | `"ImplementationSpecific"` | Default path type for the Ingress |
| ingress.defaultBackend | object | `{}` | Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces the deprecated annotation `kubernetes.io/ingress.class`) |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template |
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release |
| commonAnnotations | object | `{}` | Annotations to add to all deployed objects |
| commonLabels | object | `{}` | Labels to add to all deployed objects |
| studios.enabled | bool | `true` | Enable Studios feature. Refer to the subchart README for more details and the full list of configuration options |
| pipeline-optimization.enabled | bool | `true` | Enable pipeline optimization feature. Refer to the subchart README for more details and the full list of configuration options |

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
