# studios

Studios is a unified platform for interactive analysis

![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-informational?style=flat-square) ![AppVersion: 0.9.0](https://img.shields.io/badge/AppVersion-0.9.0-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

For an overview of the Seqera Studios service architecture and its requirements, refer to the [Seqera documentation](

https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization).

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- oidc token (auto set if not)

- The `.image` and the `.dbMigrationInitContainer.image` sections to point to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for cr.seqera.io or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.
- The Pipeline Optimization service database connection details under the `.database` section.
- The database connection details for the Platform MySQL database under the `.platformDatabase` section.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `0.9.0`.

When a sensitive value is required (e.g. the database password), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is used instead, the chart instructs the components to read the sensitive value from the external Secret directly, without storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/studios \
  --version 1.1.0 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/studios

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
| global.platformExternalDomain | string | `"example.com"` | Domain where Seqera Platform listens |
| global.platformServiceAddress | string | `"{{ printf \"%s-platform-backend\" .Release.Name | lower }}"` | Seqera Platform Service name: can be the internal Kubernetes hostname or an external ingress hostname. Evaluated as a template |
| global.platformServicePort | int | `8080` | Seqera Platform Service port |
| global.studiosDomain | string | `"studios.example.com"` | Domain where the Studios service listens. Make sure the TLS certificate covers this and its wildcard subdomains. Evaluated as a template |
| global.studiosConnectionUrl | string | `"{{ printf \"https://connect.%s\" (tpl .Values.global.studiosDomain $) }}"` | Base URL for Studios connections: can be any value, since each session will use a unique subdomain under `.global.studiosDomain` anyway to connect. Evaluated as a template |
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| global.imageCredentialsSecrets | list | `[]` | Optional list of existing Secrets containing image pull credentials to use for pulling images from private registries. These Secrets are shared with all the subcharts automatically |
| redis.host | string | `""` | Redis hostname |
| redis.port | int | `6379` | Redis port |
| redis.database | int | `0` | Redis database number |
| redis.password | string | `""` | Redis password if the installation requires it |
| redis.existingSecretName | string | `""` | Name of an existing Secret containing credentials for Redis, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| redis.existingSecretKey | string | `"CONNECT_REDIS_PASSWORD"` | Key in the existing Secret containing the password for Redis |
| redis.enableTls | bool | `false` | Enable TLS when connecting to Redis |
| redis.prefix | string | `"connect:session"` | Key prefix to use when storing Studios sessions in Redis |
| proxy.image.registry | string | `""` | Proxy container image registry |
| proxy.image.repository | string | `"private/nf-tower-enterprise/data-studio/connect-proxy"` | Proxy container image repository |
| proxy.image.tag | string | `"{{ .chart.AppVersion }}"` | Proxy container image tag |
| proxy.image.digest | string | `""` | Proxy container image digest in the format `sha256:1234abcdef` |
| proxy.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Proxy container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| proxy.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| proxy.oidcClientRegistrationToken | string | `""` | Initial access token to share with Seqera Platform to restrict registration requests to only authorized OIDC clients. The token can be provided as a string of random chars or as an external k8s Secret: in the latter case, a key can also be provided. If neither a string nor a Secret is provided, the chart will generate a random token WARNING: Auto-generated random values are incompatible with Kustomize. When upgrading releases via Kustomize, Helm cannot query the cluster to check if a secret already exists, causing it to regenerate a new random value on each upgrade, which may break existing OIDC sessions. Always explicitly set this value or use an existing secret when using Kustomize. |
| proxy.oidcClientRegistrationTokenSecretName | string | `""` | Name of an existing Secret containing the OIDC client registration token as an alternative to the oidcClientRegistrationToken field. Note: the Secret must already exist in the same namespace at the time of deployment |
| proxy.oidcClientRegistrationTokenSecretKey | string | `"OIDC_CLIENT_REGISTRATION_TOKEN"` | Key in the existing Secret containing the OIDC client registration token |
| proxy.localCacheTTL | string | `"2m"` | TTL for local cache of Redis keys used for resiliency against Redis failures |
| proxy.service.type | string | `"ClusterIP"` | Proxy Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| proxy.service.http.name | string | `"http"` | Service name to use |
| proxy.service.http.port | int | `80` | Service port |
| proxy.service.http.targetPort | int | `8081` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| proxy.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| proxy.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| proxy.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| proxy.initContainers | list | `[]` | Additional init containers for the proxy pod. Evaluated as a template |
| proxy.command | list | `[]` | Override default container command (useful when using custom images) |
| proxy.args | list | `[]` | Override default container args (useful when using custom images) |
| proxy.podLabels | object | `{}` | Additional labels for the proxy pod. Evaluated as a template |
| proxy.podAnnotations | object | `{}` | Additional annotations for the proxy pod. Evaluated as a template |
| proxy.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| proxy.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |
| proxy.extraEnvVars | list | `[]` | Extra environment variables to set on the proxy pod |
| proxy.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| proxy.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| proxy.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| proxy.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| proxy.extraOptionsSpec | object | `{"replicas":2}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| proxy.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |
| proxy.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| proxy.podSecurityContext.fsGroup | int | `65532` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| proxy.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| proxy.containerSecurityContext.runAsUser | int | `65532` | UID the container processes run as (overrides container image default) |
| proxy.containerSecurityContext.runAsGroup | int | `65532` | GID the container processes run as (overrides container image default) |
| proxy.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| proxy.containerSecurityContext.readOnlyRootFilesystem | bool | `false` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| proxy.containerSecurityContext.capabilities | object | `{"add":["NET_BIND_SERVICE"],"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| proxy.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| server.image.registry | string | `""` | Server container image registry |
| server.image.repository | string | `"private/nf-tower-enterprise/data-studio/connect-server"` | Server container image repository |
| server.image.tag | string | `"{{ .chart.AppVersion }}"` | Server container image tag |
| server.image.digest | string | `""` | Server container image digest in the format `sha256:1234abcdef` |
| server.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Server container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| server.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| server.tunnelPort | int | `7070` | Port that proxy contacts the server at to create a new tunnel |
| server.listenerPort | int | `7777` | Port where the server listens for connections from the Studios clients |
| server.service.type | string | `"ClusterIP"` | Server Service type. There should be no need to expose the Studios Server service outside of the cluster, since traffic goes through the proxy |
| server.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| server.service.extraOptions | object | `{"clusterIP":"None"}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| server.logLevel | string | `"info"` | Server log level, one of: `trace`, `debug`, `info`, `warn`, `error`, `fatal` |
| server.initContainers | list | `[]` | Additional init containers for the server pod. Evaluated as a template |
| server.command | list | `[]` | Override default container command (useful when using custom images) |
| server.args | list | `[]` | Override default container args (useful when using custom images) |
| server.podLabels | object | `{}` | Additional labels for the server pod. Evaluated as a template |
| server.podAnnotations | object | `{}` | Additional annotations for the server pod. Evaluated as a template |
| server.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| server.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |
| server.extraEnvVars | list | `[]` | Extra environment variables to set on the server pod |
| server.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| server.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| server.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| server.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| server.extraOptionsSpec | object | `{"replicas":2}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| server.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |
| server.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| server.podSecurityContext.fsGroup | int | `65532` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| server.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| server.containerSecurityContext.runAsUser | int | `65532` | UID the container processes run as (overrides container image default) |
| server.containerSecurityContext.runAsGroup | int | `65532` | GID the container processes run as (overrides container image default) |
| server.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| server.containerSecurityContext.readOnlyRootFilesystem | bool | `false` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| server.containerSecurityContext.capabilities | object | `{"add":["NET_BIND_SERVICE"],"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| server.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies (for example, wait for Seqera Platform readiness before starting, etc) |
| initContainerDependencies.waitForPlatform.enabled | bool | `true` | Enable wait for Seqera Platform init container before starting the proxy |
| initContainerDependencies.waitForPlatform.image.registry | string | `""` | Wait for Platform init container image registry |
| initContainerDependencies.waitForPlatform.image.repository | string | `"curlimages/curl"` | Wait for Platform init container image repository |
| initContainerDependencies.waitForPlatform.image.tag | string | `"latest"` | Wait for Platform init container image tag |
| initContainerDependencies.waitForPlatform.image.digest | string | `""` | Wait for Platform init container image digest in the format `sha256:1234abcdef` |
| initContainerDependencies.waitForPlatform.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the wait for Platform init container |
| initContainerDependencies.waitForPlatform.securityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| initContainerDependencies.waitForPlatform.securityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| initContainerDependencies.waitForPlatform.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| initContainerDependencies.waitForPlatform.securityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| initContainerDependencies.waitForPlatform.resources | object | `{"limits":{"memory":"100Mi"},"requests":{"cpu":"0.1","memory":"50Mi"}}` | Container requests and limits for different resources like CPU or memory |
| serviceAccount.name | string | `""` | Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated based on the release name |
| serviceAccount.annotations | object | `{}` | Additional annotations for the ServiceAccount to generate |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automount service account token when the ServiceAccount is generated |
| ingress.enabled | bool | `false` | Enable ingress for Studios Proxy |
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
