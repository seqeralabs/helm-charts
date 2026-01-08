# pipeline-optimization

A Helm chart to deploy the Seqera Pipeline Optimization service (referred to as Groundswell in Platform configuration files).

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.7](https://img.shields.io/badge/AppVersion-0.4.7-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

For an overview of the Seqera Pipeline Optimization service architecture and its requirements, refer to the [Seqera documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization).

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- The `.image` and the `.dbMigrationInitContainer.image` sections to point to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for cr.seqera.io or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.
- The Pipeline Optimization service database connection details under the `.database` section.
- The database connection details for the Platform MySQL database under the `.platformDatabase` section.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `0.4.7`.

When a sensitive value is required (e.g. the database password), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is used instead, the chart instructs the components to read the sensitive value from the external Secret directly, without storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/pipeline-optimization \
  --version 0.1.1 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/pipeline-optimization

## Examples

Refer to the [examples directory](./examples) for different scenarios of installing the Pipeline Optimization chart.
The examples provided are showcasing possible configurations of the helm chart, and are not representative of a full installation.
Please refer to the [Seqera Pipeline Optimization documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization) for complete installation instructions.

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
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| database.host | string | `""` | Pipeline Optimization MySQL database hostname |
| database.port | int | `3306` | Pipeline Optimization MySQL database port |
| database.name | string | `""` | Pipeline Optimization MySQL database name |
| database.username | string | `""` | Pipeline Optimization MySQL database username |
| database.password | string | `""` | Pipeline Optimization MySQL database password |
| database.existingSecretName | string | `""` | Name of an existing Secret containing credentials for the Pipeline Optimization MySQL database, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| database.existingSecretKey | string | `"SWELL_DB_PASSWORD"` | Key in the existing Secret containing the password for the Pipeline Optimization MySQL database |
| database.dialect | string | `"mysql"` | Pipeline Optimization database dialect. Currently only 'mysql' is supported |
| platformDatabase.host | string | `""` | Platform MySQL database hostname |
| platformDatabase.port | int | `3306` | Platform MySQL database port |
| platformDatabase.name | string | `""` | Platform MySQL database name |
| platformDatabase.username | string | `""` | Platform MySQL database username. Can be a read-only user, since Platform Optimization does not perform write operations on the Platform database |
| platformDatabase.password | string | `""` | Platform MySQL database password |
| platformDatabase.existingSecretName | string | `""` | Name of an existing Secret containing credentials for the Platform MySQL database, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| platformDatabase.existingSecretKey | string | `"TOWER_DB_PASSWORD"` | Key in the existing Secret containing the password for the Platform MySQL database |
| image.registry | string | `""` | Pipeline Optimization container image registry |
| image.repository | string | `"private/nf-tower-enterprise/groundswell"` | Pipeline Optimization container image repository |
| image.tag | string | `"{{ .chart.AppVersion }}"` | Pipeline Optimization container image tag |
| image.digest | string | `""` | Pipeline Optimization container image digest in the format `sha256:1234abcdef` |
| image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Pipeline Optimization container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| dbMigrationInitContainer.image.registry | string | `""` | Migrate DB init container image registry |
| dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/groundswell"` | Migrate DB init container image repository |
| dbMigrationInitContainer.image.tag | string | `"{{ .chart.AppVersion }}"` | Migrate DB init container image tag |
| dbMigrationInitContainer.image.digest | string | `""` | Migrate DB init container image digest in the format `sha256:1234abcdef` |
| dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Migrate DB init container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| dbMigrationInitContainer.command | list | `["/opt/groundswell/bin/migrate-db.sh"]` | Command to run to migrate the database schema |
| dbMigrationInitContainer.args | list | `[]` |  |
| service.type | string | `"ClusterIP"` | Pipeline Optimization Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| service.http.name | string | `"http"` | Service name to use |
| service.http.port | int | `8090` | Service port number |
| service.http.targetPort | int | `8090` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). |
| service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| initContainers | list | `[]` | Additional init containers for the pipeline optimization pod. Evaluated as a template |
| command | list | `[]` | Override default container command (useful when using custom images) |
| args | list | `[]` | Override default container args (useful when using custom images) |
| podLabels | object | `{}` | Additional labels for the pipeline optimization pod. Evaluated as a template |
| podAnnotations | object | `{}` | Additional annotations for the pipeline optimization pod. Evaluated as a template |
| commonAnnotations | object | `{}` | Annotations to add to all deployed objects |
| commonLabels | object | `{}` | Labels to add to all deployed objects |
| configMapAnnotations | object | `{}` | Annotations to add specifically to the ConfigMap |
| configMapLabels | object | `{}` | Labels to add specifically to the ConfigMap |
| extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |
| extraEnvVars | list | `[]` | Extra environment variables to set on the pipeline optimization pod |
| extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| startupProbe.enabled | bool | `false` | Enable startup probe |
| startupProbe.httpGet.path | string | `"/api/v1/health"` | HTTP GET path for startup probe |
| startupProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template |
| startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| readinessProbe.enabled | bool | `true` | Enable readiness probe |
| readinessProbe.httpGet.path | string | `"/api/v1/health"` | HTTP GET path for readiness probe |
| readinessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template |
| readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| livenessProbe.enabled | bool | `true` | Enable liveness probe |
| livenessProbe.httpGet.path | string | `"/api/v1/health"` | HTTP GET path for liveness probe |
| livenessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template |
| livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies (for example, wait for database readiness before starting, etc) |
| initContainerDependencies.waitForMySQL.enabled | bool | `true` | Enable wait for MySQL init container before starting pipeline optimization and cron |
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
| serviceAccount.name | string | `""` | Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated based on the release name |
| serviceAccount.annotations | object | `{}` | Additional annotations for the Platform ServiceAccount to generate |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `false` | Automount service account token when the server service account is generated |

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
