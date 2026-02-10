# agent-backend

Backend service for Seqera CLI AI capabilities

![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- The `.image` section to point to your container registry.
- The database connection details for the Agent Backend MySQL database under the `.database` section.
- Anthropic API credentials under `.anthropicApiKey` or `.anthropicApiKeyExistingSecretName`.
- LangChain API credentials under `.langchainApiKey` or `.langchainApiKeyExistingSecretName`.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for cr.seqera.io or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `0.1.0`.

When a sensitive value is required (e.g. the database password), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is used instead, the chart instructs the components to read the sensitive value from the external Secret directly, without further storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/agent-backend \
  --version 0.1.4 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/agent-backend

## Upgrading the chart

When upgrading between versions, please refer to the [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration instructions.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../../../seqera-common | seqera-common | 1.x.x |
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platformExternalDomain | string | `"example.com"` | Domain where Seqera Platform listens |
| global.agentBackendDomain | string | `"{{ printf \"ai.%s\" .Values.global.platformExternalDomain }}"` | Domain where the Agent Backend service listens. Evaluated as a template |
| global.mcpDomain | string | `"{{ printf \"mcp.%s\" .Values.global.platformExternalDomain }}"` | Domain where Seqera MCP listens. Evaluated as a template |
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| global.imageCredentialsSecrets | list | `[]` | Optional list of existing Secrets containing image pull credentials to use for pulling images from private registries. These Secrets are shared with all the subcharts automatically |
| database.host | string | `""` | MySQL database hostname |
| database.port | int | `3306` | MySQL database port |
| database.name | string | `""` | MySQL database name |
| database.username | string | `""` | MySQL database username |
| database.password | string | `""` | MySQL database password |
| database.existingSecretName | string | `""` | Name of an existing Secret containing credentials for the MySQL database, as an alternative to the password field. Note: the Secret must already exist in the  same namespace at the time of deployment |
| database.existingSecretKey | string | `"AGENT_BACKEND_DB_PASSWORD"` | Key in the existing Secret containing the password for the MySQL database |
| image.registry | string | `""` | Container image registry |
| image.repository | string | `"private/nf-tower-enterprise/agent-backend"` | Container image repository |
| image.tag | string | `"{{ .chart.AppVersion }}"` | Container image tag |
| image.digest | string | `""` | Container image digest in the format `sha256:1234abcdef` |
| image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| anthropicApiKey | string | `""` | Anthropic API key. Define the value as a String or a Secret, not both at the same time |
| anthropicApiKeyExistingSecretName | string | `""` | Name of an existing Secret containing the Anthropic API key. Note: the Secret must already exist in the same namespace at the time of deployment |
| anthropicApiKeyExistingSecretKey | string | `"ANTHROPIC_API_KEY"` | Key in the existing Secret containing the Anthropic API key |
| langchainApiKey | string | `""` | LangChain API key. Define the value as a String or a Secret, not both at the same time |
| langchainApiKeyExistingSecretName | string | `""` | Name of an existing Secret containing the LangChain API key. Note: the Secret must already exist in the same namespace at the time of deployment |
| langchainApiKeyExistingSecretKey | string | `"LANGCHAIN_API_KEY"` | Key in the existing Secret containing the LangChain API key |
| environment | string | `"production"` | Environment (e.g., production, development) |
| logLevel | string | `"INFO"` | Log level (e.g., DEBUG, INFO, WARNING, ERROR) |
| anthropicModel | string | `"claude-sonnet-4-20250514"` | Anthropic model to use |
| service | object | `{"extraOptions":{},"extraServices":[],"http":{"name":"http","nodePort":null,"port":80,"targetPort":8002},"type":"ClusterIP"}` | Service configuration |
| service.type | string | `"ClusterIP"` | Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| service.http.name | string | `"http"` | Service name to use |
| service.http.port | int | `80` | Service port |
| service.http.targetPort | int | `8002` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| dbMigrationInitContainer.command | list | `["./init.sh"]` | Command to run in the init container performing DB migrations |
| dbMigrationInitContainer.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| dbMigrationInitContainer.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| dbMigrationInitContainer.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| dbMigrationInitContainer.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| dbMigrationInitContainer.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.5","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| initContainers | list | `[]` | Additional init containers for the pod. Evaluated as a template |
| command | list | `[]` | Override default container command (useful when using custom images) |
| args | list | `[]` | Override default container args (useful when using custom images) |
| podLabels | object | `{}` | Additional labels for the pod. Evaluated as a template |
| podAnnotations | object | `{}` | Additional annotations for the pod. Evaluated as a template |
| extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |
| extraEnvVars | list | `[]` | Extra environment variables |
| extraEnvVarsCMs | list | `[]` | List of ConfigMaps containing extra env vars |
| extraEnvVarsSecrets | list | `[]` | List of Secrets containing extra env vars |
| extraVolumes | list | `[]` | List of volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| extraVolumeMounts | list | `[]` | List of volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies |
| initContainerDependencies.waitForMySQL.enabled | bool | `true` | Enable wait for MySQL init container before starting the main container |
| initContainerDependencies.waitForMySQL.image.registry | string | `""` | Override default wait for MySQL init container image |
| initContainerDependencies.waitForMySQL.image.repository | string | `"mysql"` |  |
| initContainerDependencies.waitForMySQL.image.tag | string | `"9"` |  |
| initContainerDependencies.waitForMySQL.image.digest | string | `""` |  |
| initContainerDependencies.waitForMySQL.image.pullPolicy | string | `"IfNotPresent"` |  |
| initContainerDependencies.waitForMySQL.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| initContainerDependencies.waitForMySQL.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID is 0) |
| initContainerDependencies.waitForMySQL.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| initContainerDependencies.waitForMySQL.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| initContainerDependencies.waitForMySQL.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.5","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| startupProbe.enabled | bool | `false` | Enable startup probe |
| startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe |
| startupProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template |
| startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| readinessProbe.enabled | bool | `true` | Enable readiness probe |
| readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe |
| readinessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template |
| readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| livenessProbe.enabled | bool | `true` | Enable liveness probe |
| livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe |
| livenessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template |
| livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":true,"imagePullSecretNames":[],"name":""}` | Service account configuration |
| serviceAccount.name | string | `""` | Service account name |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automatically mount service account token |
| ingress.enabled | bool | `false` | Enable ingress for Agent Backend |
| ingress.path | string | `"/"` | Path for the main ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller |
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
| secretLabels | object | `{}` | Additional labels for the Secret objects. Evaluated as a template |
| secretAnnotations | object | `{}` | Additional annotations for the Secret objects. Evaluated as a template |
| configMapLabels | object | `{}` | Additional labels for the ConfigMap objects. Evaluated as a template |
| configMapAnnotations | object | `{}` | Additional annotations for the ConfigMap objects. Evaluated as a template |

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
