# portal-web

Portal web frontend for Seqera Platform

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.7.2](https://img.shields.io/badge/AppVersion-1.7.2-informational?style=flat-square)

Some basic familiarity with Helm is assumed. If you are new to Helm, please refer to the [Helm documentation](https://helm.sh/docs/).
We recommend reading through the `values.yaml` file to understand the configuration options available for the chart. Each entry is documented with `# --` comments describing its purpose and usage. Other annotations are used to automatically generate the README files and can be ignored:
- `# @section` — groups related values under a heading in the generated README
- `# @default` — documents a default value that is computed in the templates rather than set literally in `values.yaml`

## Requirements and configuration

For a full list of prerequisites needed to deploy Seqera AI, refer to the [Seqera AI prerequisites](https://docs.seqera.io/platform-enterprise/seqera-ai/prerequisites) documentation.

Note that the Seqera charts do not automatically set `cr.seqera.io` as the registry where to pull images from, as we want to encourage users to use their own registries to improve reliability: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/configuration/mirroring). We also recommend [vendoring the Seqera charts](https://github.com/seqeralabs/helm-charts/blob/master/VENDORING.md).

The required values to set in order to have a working installation are:
- The `.global.portalWebDomain` set to the domain where the Seqera Portal Web will be exposed.
- The `.global.platformExternalDomain` and `.global.agentBackendDomain` set to the domains where Seqera Platform and Agent Backend are exposed, respectively, since they both are requirements for the Portal application.
- The Seqera Platform Service connection details under `.global.platformServiceAddress` and `.global.platformServicePort`. These point to the Platform backend service that Portal Web communicates with. When deploying this subchart as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section.
- The `.image` section pointing to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for `cr.seqera.io` or your private registry where you vendored the images to).
  Alternatively, to avoid storing sensitive credentials in the values file, you can create a Kubernetes Secret containing the credentials and reference it in the `.global.imageCredentialsSecrets` value. Refer to [the Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line) to create a Kubernetes Secret to store image pull credentials.
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries or repositories within the same registry, e.g. you can set credentials for `cr.seqera.io/enterprise` (where Platform images are located) and `cr.seqera.io/ai` (where Seqera AI products are located).
  * Additional pull secrets can be defined in each `.image` section to extend the global credentials, if that image is located in a different registry.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, they won't replace them.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `1.7.2`.

## Installing the chart

To install the chart:

1. Download the default values file:
   ```console
   helm show values oci://public.cr.seqera.io/charts/portal-web --version 0.4.0 > values.yaml
   ```
2. Edit `values.yaml` to match your environment. We recommend removing entries whose defaults you don't need to override — this keeps your configuration file focused and easier to maintain across upgrades.
3. Install the chart with the release name `my-release`:
   ```console
   helm install my-release oci://public.cr.seqera.io/charts/portal-web \
     --version 0.4.0 \
     --namespace my-namespace \
     --create-namespace \
     -f values.yaml
   ```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/portal-web

### Alternative: installing from the Helm repository

Charts are also published to a traditional Helm repository. This can be useful in environments where pulling from OCI registries is restricted:

```console
helm repo add seqeralabs https://seqeralabs.github.io/helm-charts
helm repo update
helm install my-release seqeralabs/portal-web \
  --version 0.4.0 \
  --namespace my-namespace \
  --create-namespace \
  -f values.yaml
```

## Upgrading the chart

When upgrading between versions, please refer to the [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration instructions.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../../../seqera-common | seqera-common | 3.x.x |
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platformExternalDomain | string | `"example.com"` | Domain where Seqera Platform listens |
| global.platformServiceAddress | string | `""` | Seqera Platform Service name: can be the internal Kubernetes hostname or an external ingress hostname. Evaluated as a template. Required when deploying this subchart standalone. When deploying as part of the parent `platform` umbrella chart, this value is inherited from the parent chart's `global` section |
| global.platformServicePort | int | `nil` | Seqera Platform Service port. Required when deploying this subchart standalone. When deploying as part of the parent `platform` umbrella chart, this value is inherited from the parent chart's `global` section |
| global.agentBackendDomain | string | `"{{ printf \"ai-api.%s\" .Values.global.platformExternalDomain }}"` | Domain where the Agent Backend service listens. Evaluated as a template |
| global.portalWebDomain | string | `"{{ printf \"ai.%s\" .Values.global.platformExternalDomain }}"` | Domain where the Portal Web frontend listens. Evaluated as a template |

### Global: Ingress defaults

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.ingress.enabled | bool | `false` | Enable Ingress for this chart. OR'd with the chart's local `ingress.enabled` so setting this once at the parent enables all subchart Ingresses. |
| global.ingress.path | string | `"/"` | Default path applied to ingress rules when `ingress.path` is not set. AWS ALB users should override to `/*`. |
| global.ingress.defaultPathType | string | `"Prefix"` | Default path type applied to ingress rules when `ingress.defaultPathType` is not set. `Prefix` works for nginx, traefik, AWS ALB, and most modern controllers. |
| global.ingress.ingressClassName | string | `""` | Default ingress class name applied when `ingress.ingressClassName` is not set |
| global.ingress.annotations | object | `{}` | Annotations merged into the Ingress. Local `ingress.annotations` wins on key collision. Evaluated as a template |
| global.ingress.extraLabels | object | `{}` | Extra labels merged into the Ingress. Local `ingress.extraLabels` wins on key collision. Evaluated as a template |
| global.ingress.tls | list | `[]` | TLS entries concatenated with the local `ingress.tls`. Evaluated as a template |

### Global: Gateway API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.httpRoute.enabled | bool | `false` | Enable HTTPRoute for this chart. OR'd with the chart's local `httpRoute.enabled` so setting this once at the parent enables all subchart HTTPRoutes. Independent from `ingress.enabled` |
| global.httpRoute.parentRefs | list | `[]` | Parent Gateway(s) this chart's HTTPRoute attaches to. Applied when the local `httpRoute.parentRefs` is not set. Each entry accepts `name` (required), `namespace`, `sectionName`, `port`, `kind`, and `group`. Evaluated as a template |
| global.httpRoute.path | string | `"/"` | Default path applied to HTTPRoute rules when `httpRoute.path` is not set |
| global.httpRoute.matchType | string | `"PathPrefix"` | Default path match type applied when `httpRoute.matchType` is not set. One of `PathPrefix`, `Exact`, or `RegularExpression` |
| global.httpRoute.annotations | object | `{}` | Annotations merged into the HTTPRoute. Local `httpRoute.annotations` wins on key collision. Evaluated as a template |
| global.httpRoute.extraLabels | object | `{}` | Extra labels merged into the HTTPRoute. Local `httpRoute.extraLabels` wins on key collision. Evaluated as a template |

### Global: Image credentials

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| global.imageCredentialsSecrets | list | `[]` | Optional list of existing Secrets containing image pull credentials to use for pulling images from private registries. These Secrets are shared with all the subcharts automatically |

### Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.registry | string | `""` | Container image registry |
| image.repository | string | `"ai/portal/web"` | Container image repository |
| image.tag | string | `"{{ .chart.AppVersion }}"` | Container image tag |
| image.digest | string | `""` | Container image digest in the format `sha256:1234abcdef` |
| image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |

### Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| service.type | string | `"ClusterIP"` | Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| service.http.name | string | `"http"` | Service name to use |
| service.http.port | int | `80` | Service port |
| service.http.targetPort | int | `3000` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tmpDirSizeLimit | string | `"500Mi"` | Size limit for the /tmp emptyDir volume |
| nextjsCacheSizeLimit | string | `"500Mi"` | Size limit for the /app/.next/cache emptyDir volume |
| initContainers | list | `[]` | Additional init containers for the pod. Evaluated as a template |
| command | list | `[]` | Override default container command (useful when using custom images) |
| args | list | `[]` | Override default container args (useful when using custom images) |
| podLabels | object | `{}` | Additional labels for the pod. Evaluated as a template |
| podAnnotations | object | `{}` | Additional annotations for the pod. Evaluated as a template |
| extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |

### Deployment: Environment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraEnvVars | list | `[]` | Extra environment variables |
| extraEnvVarsCMs | list | `[]` | List of ConfigMaps containing extra env vars |
| extraEnvVarsSecrets | list | `[]` | List of Secrets containing extra env vars |
| extraVolumes | list | `[]` | List of volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| extraVolumeMounts | list | `[]` | List of volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |

### Security Context: Pod

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| podSecurityContext.fsGroup | int | `1001` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |

### Security Context: Container

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| containerSecurityContext.runAsUser | int | `1001` | UID the container processes run as (overrides container image default) |
| containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |

### Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| resources | object | `{"limits":{"memory":"500Mi"},"requests":{"cpu":"100m","memory":"500Mi"}}` | Container requests and limits for different resources like CPU or memory |

### Probes: Startup

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| startupProbe.enabled | bool | `false` | Enable startup probe |
| startupProbe.httpGet.path | string | `"/"` | HTTP GET path for startup probe |
| startupProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template |
| startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |

### Probes: Readiness

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| readinessProbe.enabled | bool | `true` | Enable readiness probe |
| readinessProbe.httpGet.path | string | `"/"` | HTTP GET path for readiness probe |
| readinessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template |
| readinessProbe.initialDelaySeconds | int | `10` | Delay before first check |
| readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| readinessProbe.failureThreshold | int | `3` | Consecutive failures before marking the container Unready (no restart) |
| readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |

### Probes: Liveness

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| livenessProbe.enabled | bool | `true` | Enable liveness probe |
| livenessProbe.httpGet.path | string | `"/"` | HTTP GET path for liveness probe |
| livenessProbe.httpGet.port | string | `"{{ .Values.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template |
| livenessProbe.initialDelaySeconds | int | `30` | Delay before first check |
| livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| livenessProbe.timeoutSeconds | int | `5` | Short timeout to detect hung containers quickly |
| livenessProbe.failureThreshold | int | `3` | Consecutive failures before restarting the container |
| livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |

### Service Account

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":true,"imagePullSecretNames":[],"name":""}` | Service account configuration |
| serviceAccount.create | bool | `true` | Whether to create a ServiceAccount. When `true`, the ServiceAccount named by `serviceAccount.name` is created (a `<release>-<chart>-sa` name is generated when it is unset). Set to `false` to use an existing, externally-managed ServiceAccount referenced by `serviceAccount.name`. |
| serviceAccount.name | string | `""` | Name of the ServiceAccount used by this chart's workloads. When empty, a name is generated from the release name. Applies whether the ServiceAccount is created by this chart (`create: true`) or managed externally (`create: false`). |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `false` | Automatically mount service account token |

### Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.enabled | bool | `false` | Enable ingress for Portal Web |
| ingress.path | string | `""` | Path for the main ingress rule. When empty, falls back to `global.ingress.path` |
| ingress.defaultPathType | string | `""` | Default path type for the Ingress. When empty, falls back to `global.ingress.defaultPathType` |
| ingress.defaultBackend | object | `{}` | Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces the deprecated annotation `kubernetes.io/ingress.class`). When empty, falls back to `global.ingress.ingressClassName` |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template |

### Gateway API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| httpRoute.enabled | bool | `false` | Enable HTTPRoute for Portal Web |
| httpRoute.parentRefs | list | `[]` | Gateway(s) this HTTPRoute attaches to. When empty, falls back to `global.httpRoute.parentRefs`. Each entry accepts `name` (required), `namespace`, `sectionName`, `port`, `kind`, and `group`. Evaluated as a template |
| httpRoute.path | string | `""` | Path for the main HTTPRoute rule. When empty, falls back to `global.httpRoute.path` |
| httpRoute.matchType | string | `""` | Path match type for the HTTPRoute. One of `PathPrefix`, `Exact`, or `RegularExpression`. When empty, falls back to `global.httpRoute.matchType` |
| httpRoute.extraHosts | list | `[]` | Additional hosts you want to route. Each host becomes its own HTTPRoute. Evaluated as a template |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations. Evaluated as a template |
| httpRoute.extraLabels | object | `{}` | Additional labels for the HTTPRoute object. Evaluated as a template |

### Extra Deploy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release |

### Common Metadata

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
