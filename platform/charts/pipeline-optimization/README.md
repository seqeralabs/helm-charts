# pipeline-optimization

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.7](https://img.shields.io/badge/AppVersion-0.4.7-informational?style=flat-square)

A Helm chart to deploy the Seqera Pipeline Optimization service (referred to as Groundswell in Platform configuration files).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Seqera Labs | <devops@seqera.io> | <https://seqera.io> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.pipelineOptimizationExternalDomain | string | `""` | External domain name where the Pipeline Optimization service will be exposed. This value will be used by the main Platform parent chart and to configure the ingress hostname, if enabled |
| global.imageCredentials | list | `[]` | Optional credentials to log in and fetch images from a private registry  <pre><code> - registry: ""</br>   username: ""</br>   password: ""</br>   email: someone@example.com  # Optional </code></pre> |
| database.host | string | `""` | Pipeline Optimization MySQL database hostname |
| database.port | int | `3306` | Pipeline Optimization MySQL database port |
| database.name | string | `""` | Pipeline Optimization MySQL database name |
| database.username | string | `""` | Pipeline Optimization MySQL database username |
| database.password | string | `""` | Pipeline Optimization MySQL database password |
| database.existingSecretName | string | `""` | Name of an existing secret containing credentials for the Pipeline Optimization MySQL database Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| database.existingSecretKey | string | "SWELL_DB_PASSWORD" | Key in the existing secret containing the password for the Pipeline Optimization MySQL database |
| database.dialect | string | `"mysql"` | Pipeline Optimization database dialect. Currently only 'mysql' is supported |
| platformDatabase.host | string | `""` | Platform MySQL database hostname |
| platformDatabase.port | int | `3306` | Platform MySQL database port |
| platformDatabase.name | string | `""` | Platform MySQL database name |
| platformDatabase.username | string | `""` | Platform MySQL database username. Can be a read-only user, since Platform Optimization does not perform write operations on the Platform database |
| platformDatabase.password | string | `""` | Platform MySQL database password |
| platformDatabase.existingSecretName | string | `""` | Name of an existing secret containing credentials for the Platform MySQL database Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| platformDatabase.existingSecretKey | string | "TOWER_DB_PASSWORD" | Key in the existing secret containing the password for the Platform MySQL database |
| image.registry | string | `""` | Pipeline Optimization container image registry |
| image.repository | string | `"private/nf-tower-enterprise/groundswell"` | Pipeline Optimization container image repository |
| image.tag | string | "{{ .chart.AppVersion }}" | Pipeline Optimization container image tag |
| image.digest | string | `""` | Pipeline Optimization container image digest in the format <code>sha256:1234abcdef</code> |
| image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Pipeline Optimization container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre> |
| dbMigrationInitContainer.image.registry | string | `""` | Migrate DB init container image registry |
| dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/groundswell"` | Migrate DB init container image repository |
| dbMigrationInitContainer.image.tag | string | "{{ .chart.AppVersion }}" | Migrate DB init container image tag |
| dbMigrationInitContainer.image.digest | string | `""` | Migrate DB init container image digest in the format <code>sha256:1234abcdef</code> |
| dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the Migrate DB init container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| dbMigrationInitContainer.command | list | `["/opt/groundswell/bin/migrate-db.sh"]` | Command to run to migrate the database schema |
| dbMigrationInitContainer.args | list | `[]` |  |
| service.type | string | `"ClusterIP"` | Pipeline Optimization Service type Note: ingresses using AWS ALB require the service to be NodePort |
| service.http.name | string | `"http"` | Service name to use |
| service.http.port | int | `8090` | Service port number |
| service.http.targetPort | int | `8090` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). |
| service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  <pre><code> extraServices:<br> - name: myspecialservice<br>   port: 1234<br>   targetPort: 5678<br>   nodePort: null </code></pre> |
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
| extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template  <pre><code> extraOptionsSpec:<br>   replicas: 2<br>   strategy:<br>     rollingUpdate:<br>       maxUnavailable: x<br>       maxSurge: y </code></pre> |
| extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template  <pre><code> extraOptionsTemplateSpec:<br>   nodeSelector:<br>     service: myspecialnodegroup </code></pre> |
| extraEnvVars | list | `[]` | Extra environment variables to set on the pipeline optimization pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre> |
| extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code> |
| extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code> |
| podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access |
| containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0) |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| resources | object | `{}` | Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "1"<br>     memory: "1000Mi"<br>   limits:<br>     memory: "1000Mi" </code></pre> |
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
| ingress.enabled | bool | `false` | Enable ingress for the Pipeline Optimization frontend service |
| ingress.path | string | `"/"` | Ingress path |
| ingress.contentPath | string | `"/"` | Content path for content domain ingress |
| ingress.defaultPathType | string | `"ImplementationSpecific"` | Default path type for the Ingress |
| ingress.defaultBackend | object | `{}` | Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems  <pre><code> defaultBackend:<br>   service:<br>     name: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'<br>     port:<br>       number: '{{ .Values.frontend.service.http.port }}' </code></pre> |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template  <pre><code> extraHosts:<br>   - host: '{{ printf "api.%s" .Values.global.pipelineOptimizationExternalDomain }}'<br>     paths:<br>       - path: /*<br>         pathType: Prefix  # Optional, defaults to defaultPathType<br>         serviceName: '{{ include "common.names.fullname" . }}'<br>         portNumber: '{{ .Values.service.http.port }}' </code></pre> |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces deprecated annotation 'kubernetes.io/ingress.class') |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template  <pre><code> tls:<br>   - hosts:<br>       - '{{ .Values.global.pipelineOptimizationExternalDomain }}'<br>     secretName: my-tls </code></pre> |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
