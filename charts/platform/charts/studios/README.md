# studios

Studios is a unified platform for interactive analysis

![Version: 1.7.0](https://img.shields.io/badge/Version-1.7.0-informational?style=flat-square) ![AppVersion: 0.11.1](https://img.shields.io/badge/AppVersion-0.11.1-informational?style=flat-square)

Some basic familiarity with Helm is assumed. If you are new to Helm, please refer to the [Helm documentation](https://helm.sh/docs/).
We recommend reading through the `values.yaml` file to understand the configuration options available for the chart. Each entry is documented with `# --` comments describing its purpose and usage. Other annotations are used to automatically generate the README files and can be ignored:
- `# @section` — groups related values under a heading in the generated README
- `# @default` — documents a default value that is computed in the templates rather than set literally in `values.yaml`

## Requirements and configuration

For an overview of the Seqera Studios service architecture and its requirements, refer to the [Seqera documentation](https://docs.seqera.io/platform-enterprise/enterprise/install-studios).

Note that the Seqera charts do not automatically set `cr.seqera.io` as the registry where to pull images from, as we want to encourage users to use their own registries to improve reliability: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/configuration/mirroring). We also recommend [vendoring the Seqera charts](https://github.com/seqeralabs/helm-charts/blob/master/VENDORING.md).

The required values to set in order to have a working installation are:
- The domain where Seqera Studios is accessible, set at `.global.studiosDomain`, which defaults to the subdomain `studios.<platformExternalDomain>`. The wildcard subdomain where Studios sessions will be created is set at `.global.studiosSessionWildcardDomain`, which defaults to `*.<studiosDomain>`.
- The domain where Seqera Platform is accessible, set under `.global.platformExternalDomain`.
- The Seqera Platform Service connection details under `.global.platformServiceAddress` and `.global.platformServicePort`. These point to the Platform backend service that Studios communicates with. When deploying this subchart as part of the parent `platform` umbrella chart, these values are inherited automatically from the parent chart's `global` section.
- The OIDC client registration token under `.proxy.oidcClientRegistrationToken` (or reference an existing Secret with `.proxy.oidcClientRegistrationTokenSecretName`). When deploying as part of the platform parent chart this is set automatically; when deploying standalone it must match the value configured in the platform backend.
- The `.image` and the `.dbMigrationInitContainer.image` sections to point to your container registry.
- The redis connection details under the `.redis` section.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for `cr.seqera.io` or your private registry where you vendored the images to).
  Alternatively, to avoid storing sensitive credentials in the values file, you can create a Kubernetes Secret containing the credentials and reference it in the `.global.imageCredentialsSecrets` value. Refer to [the Kubernetes docs](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line) to create a Kubernetes Secret to store image pull credentials.
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries or repositories within the same registry, e.g. you can set credentials for `cr.seqera.io/enterprise` (where Platform images are located) and `cr.seqera.io/ai` (where Seqera AI products are located).
  * Additional pull secrets can be defined in each `.image` section to extend the global credentials, if that image is located in a different registry.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, they won't replace them.
- Define appropriate resources for each component, look for `resources` sections in the `values.yaml` file, sane defaults are recommended in a comment; more details [here](https://github.com/seqeralabs/helm-charts/blob/master/charts/platform/docs/resources.md).

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `0.11.1`.

When a sensitive value is required (e.g. the database password, the Seqera license key), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is used instead, the chart instructs the components to read the sensitive value from the external Secret directly, without further storing copies of the sensitive value in the chart-created Secret.
Refer to [this example](https://github.com/seqeralabs/helm-charts/tree/master/charts/platform/examples/passwords-from-secrets) for a demonstration of how to create a Kubernetes Secret to store sensitive values.

## Installing the chart

To install the chart:

1. Download the default values file:
   ```console
   helm show values oci://public.cr.seqera.io/charts/studios --version 1.7.0 > values.yaml
   ```
2. Edit `values.yaml` to match your environment. We recommend removing entries whose defaults you don't need to override — this keeps your configuration file focused and easier to maintain across upgrades.
3. Install the chart with the release name `my-release`:
   ```console
   helm install my-release oci://public.cr.seqera.io/charts/studios \
     --version 1.7.0 \
     --namespace my-namespace \
     --create-namespace \
     -f values.yaml
   ```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/studios

### Alternative: installing from the Helm repository

Charts are also published to a traditional Helm repository. This can be useful in environments where pulling from OCI registries is restricted:

```console
helm repo add seqeralabs https://seqeralabs.github.io/helm-charts
helm repo update
helm install my-release seqeralabs/studios \
  --version 1.7.0 \
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

### Global: Studios

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.studiosDomain | string | `"{{ printf \"studios.%s\" .Values.global.platformExternalDomain }}"` | Domain where the Studios service listens. Make sure the TLS certificate covers this and its wildcard subdomains. Evaluated as a template |
| global.studiosConnectionUrl | string | `"{{ printf \"https://connect.%s\" (tpl .Values.global.studiosDomain $) }}"` | Base URL for Studios connections: can be any value, since each session will use a unique subdomain under `.global.studiosDomain` anyway to connect. Evaluated as a template |

### Global: Ingress

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

### Global: Image Credentials

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically |
| global.imageCredentialsSecrets | list | `[]` | Optional list of existing Secrets containing image pull credentials to use for pulling images from private registries. These Secrets are shared with all the subcharts automatically |

### Redis

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| redis.host | string | `""` | Redis hostname |
| redis.port | int | `6379` | Redis port |
| redis.database | int | `0` | Redis database number |
| redis.password | string | `""` | Redis password if the installation requires it |
| redis.existingSecretName | string | `""` | Name of an existing Secret containing credentials for Redis, as an alternative to the password field. Note: the Secret must already exist in the same namespace at the time of deployment |
| redis.existingSecretKey | string | `"CONNECT_REDIS_PASSWORD"` | Key in the existing Secret containing the password for Redis |
| redis.enableTls | bool | `false` | Enable TLS when connecting to Redis |
| redis.prefix | string | `"connect:session"` | Key prefix to use when storing Studios sessions in Redis |

### Proxy: Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.image.registry | string | `""` | Proxy container image registry |
| proxy.image.repository | string | `"enterprise/studios/proxy"` | Proxy container image repository |
| proxy.image.tag | string | `"{{ .chart.AppVersion }}"` | Proxy container image tag. Defaults to the chart's appVersion (the `appVersion` field in Chart.yaml) |
| proxy.image.digest | string | `""` | Proxy container image digest in the format `sha256:1234abcdef` |
| proxy.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Proxy container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| proxy.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |

### Proxy: OIDC

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.oidcClientRegistrationToken | string | `""` | Initial access token to share with Seqera Platform to restrict registration requests to only authorized OIDC clients. The token can be provided as a string of random chars or as an external k8s Secret: in the latter case, a key can also be provided. If neither a string nor a Secret is provided, the chart will generate a random token WARNING: Always explicitly set this value or use an existing secret when using Kustomize. Auto-generated random values are incompatible with Kustomize. When upgrading releases via Kustomize, Helm cannot query the cluster to check if a secret already exists, causing it to regenerate a new random value on each upgrade |
| proxy.oidcClientRegistrationTokenSecretName | string | `""` | Name of an existing Secret containing the OIDC client registration token as an alternative to the oidcClientRegistrationToken field. Note: the Secret must already exist in the same namespace at the time of deployment |
| proxy.oidcClientRegistrationTokenSecretKey | string | `"CONNECT_OIDC_CLIENT_REGISTRATION_TOKEN"` | Key in the existing Secret containing the OIDC client registration token |

### Proxy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.localCacheTTL | string | `"2m"` | TTL for local cache of Redis keys used for resiliency against Redis failures |

### Proxy: Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.service.type | string | `"ClusterIP"` | Proxy Service type. Note: ingresses using AWS ALB require the service to be NodePort |
| proxy.service.http.name | string | `"http"` | Service name to use |
| proxy.service.http.port | int | `80` | Service port |
| proxy.service.http.targetPort | int | `8081` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| proxy.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| proxy.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| proxy.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| proxy.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| proxy.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |

### Proxy: Pod

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.initContainers | list | `[]` | Additional init containers for the proxy pod. Evaluated as a template |
| proxy.command | list | `[]` | Override default container command (useful when using custom images) |
| proxy.args | list | `[]` | Override default container args (useful when using custom images) |
| proxy.podLabels | object | `{}` | Additional labels for the proxy pod. Evaluated as a template |
| proxy.podAnnotations | object | `{}` | Additional annotations for the proxy pod. Evaluated as a template |
| proxy.extraVolumes | list | `[]` | List of volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| proxy.extraVolumeMounts | list | `[]` | List of volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| proxy.extraOptionsSpec | object | `{"replicas":2}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| proxy.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |

### Proxy: Environment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.extraEnvVars | list | `[]` | Extra environment variables to set on the proxy pod |
| proxy.extraEnvVarsCMs | list | `[]` | List of ConfigMaps containing extra env vars |
| proxy.extraEnvVarsSecrets | list | `[]` | List of Secrets containing extra env vars |

### Proxy: Security Context

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| proxy.podSecurityContext.fsGroup | int | `65532` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| proxy.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| proxy.containerSecurityContext.runAsUser | int | `65532` | UID the container processes run as (overrides container image default) |
| proxy.containerSecurityContext.runAsGroup | int | `65532` | GID the container processes run as (overrides container image default) |
| proxy.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| proxy.containerSecurityContext.readOnlyRootFilesystem | bool | `false` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| proxy.containerSecurityContext.capabilities | object | `{"add":["NET_BIND_SERVICE"],"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |

### Proxy: Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| proxy.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |

### Server: Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.image.registry | string | `""` | Server container image registry |
| server.image.repository | string | `"enterprise/studios/server"` | Server container image repository |
| server.image.tag | string | `"{{ .chart.AppVersion }}"` | Server container image tag. Defaults to the chart's appVersion (the `appVersion` field in Chart.yaml) |
| server.image.digest | string | `""` | Server container image digest in the format `sha256:1234abcdef` |
| server.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Server container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| server.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |

### Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.tunnelPort | int | `7070` | Port that proxy contacts the server at to create a new tunnel |
| server.listenerPort | int | `7777` | Port where the server listens for connections from the Studios clients |
| server.logLevel | string | `"info"` | Server log level, one of: `trace`, `debug`, `info`, `warn`, `error`, `fatal` |

### Server: Service

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.service.type | string | `"ClusterIP"` | Server Service type. There should be no need to expose the Studios Server service outside of the cluster, since traffic goes through the proxy |
| server.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| server.service.extraOptions | object | `{"clusterIP":"None"}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| server.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| server.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |

### Server: Pod

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.initContainers | list | `[]` | Additional init containers for the server pod. Evaluated as a template |
| server.command | list | `[]` | Override default container command (useful when using custom images) |
| server.args | list | `[]` | Override default container args (useful when using custom images) |
| server.podLabels | object | `{}` | Additional labels for the server pod. Evaluated as a template |
| server.podAnnotations | object | `{}` | Additional annotations for the server pod. Evaluated as a template |
| server.extraVolumes | list | `[]` | List of volumes to add to the deployment (evaluated as template). Requires setting `extraVolumeMounts` |
| server.extraVolumeMounts | list | `[]` | List of volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes` |
| server.extraOptionsSpec | object | `{"replicas":2}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template |
| server.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template |

### Server: Environment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.extraEnvVars | list | `[]` | Extra environment variables to set on the server pod |
| server.extraEnvVarsCMs | list | `[]` | List of ConfigMaps containing extra env vars |
| server.extraEnvVarsSecrets | list | `[]` | List of Secrets containing extra env vars |

### Server: Security Context

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| server.podSecurityContext.fsGroup | int | `65532` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| server.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| server.containerSecurityContext.runAsUser | int | `65532` | UID the container processes run as (overrides container image default) |
| server.containerSecurityContext.runAsGroup | int | `65532` | GID the container processes run as (overrides container image default) |
| server.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| server.containerSecurityContext.readOnlyRootFilesystem | bool | `false` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| server.containerSecurityContext.capabilities | object | `{"add":["NET_BIND_SERVICE"],"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |

### Server: Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server.resources | object | `{}` | Container requests and limits for different resources like CPU or memory |

### Init Container Dependencies

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies (for example, wait for Seqera Platform readiness before starting, etc) |

### Init Container Dependencies: Wait for Platform

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
| initContainerDependencies.waitForPlatform.extraEnvVars | list | `[]` | Additional environment variables for the init container |
| initContainerDependencies.waitForPlatform.extraVolumeMounts | list | `[]` | Additional volume mounts for the init container (e.g. to mount a CA certificate) |

### Service Account

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceAccount.create | bool | `true` | Whether to create a ServiceAccount. When `true`, the ServiceAccount named by `serviceAccount.name` is created (a `<release>-<chart>-sa` name is generated when it is unset). Set to `false` to use an existing, externally-managed ServiceAccount referenced by `serviceAccount.name`. |
| serviceAccount.name | string | `""` | Name of the ServiceAccount used by this chart's workloads. When empty, a name is generated from the release name. Applies whether the ServiceAccount is created by this chart (`create: true`) or managed externally (`create: false`). |
| serviceAccount.annotations | object | `{}` | Additional annotations for the ServiceAccount to generate |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `true` | Automount service account token when the ServiceAccount is generated |

### Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.enabled | bool | `false` | Enable ingress for Studios Proxy |
| ingress.path | string | `""` | Path for the main ingress rule. When empty, falls back to `global.ingress.path` |
| ingress.defaultPathType | string | `""` | Default path type for the Ingress. When empty, falls back to `global.ingress.defaultPathType` |
| ingress.defaultBackend | object | `{}` | Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template. Each path's backend takes either `portNumber` or `portName` (e.g. `use-annotation` to reference an ALB action defined via `ingress.annotations`). |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces the deprecated annotation `kubernetes.io/ingress.class`). When empty, falls back to `global.ingress.ingressClassName` |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template |

### Gateway API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| httpRoute.enabled | bool | `false` | Enable HTTPRoute for Studios |
| httpRoute.parentRefs | list | `[]` | Gateway(s) this HTTPRoute attaches to. When empty, falls back to `global.httpRoute.parentRefs`. Each entry accepts `name` (required), `namespace`, `sectionName`, `port`, `kind`, and `group`. Evaluated as a template |
| httpRoute.path | string | `""` | Path for the main HTTPRoute rule. When empty, falls back to `global.httpRoute.path` |
| httpRoute.matchType | string | `""` | Path match type for the HTTPRoute. One of `PathPrefix`, `Exact`, or `RegularExpression`. When empty, falls back to `global.httpRoute.matchType` |
| httpRoute.extraHosts | list | `[]` | Additional hosts you want to route. Each host becomes its own HTTPRoute. Evaluated as a template |
| httpRoute.annotations | object | `{}` | HTTPRoute annotations. Evaluated as a template |
| httpRoute.extraLabels | object | `{}` | Additional labels for the HTTPRoute object. Evaluated as a template |

### Common

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
