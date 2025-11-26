# platform

A Helm chart to deploy Seqera Platform (formerly known as Tower) on Kubernetes.

![Version: 0.17.1](https://img.shields.io/badge/Version-0.17.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.2.3](https://img.shields.io/badge/AppVersion-v25.2.3-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements

- Kubernetes 1.33+
- Helm 3.19+
- MySQL 8+ database
- Redis v7-compatible cache

For a full list of requirements, refer to the [documentation](https://docs.seqera.io/platform-enterprise/enterprise/overview).

## Platform architecture

The [Seqera Platform architecture](https://docs.seqera.io/platform-enterprise/enterprise/overview)
consists of the following components:

- Backend
  * The backend app is a JVM-based web application based on the Micronaut framework, exposing the REST API and handling most of the business logic.
- Cron pod
  * The cron app is a backend service that executes regularly-occurring activities, such as sending email notifications and cleaning up stale data. The cron service also performs database migrations at startup.
- Frontend pod
  * The frontend app is an Nginx web server for the Platform web UI.
- MySQL database to persist the Platform data.
- Redis cache.

### Redis Cache details

Multiple Seqera products require a Redis cache. Seqera strongly recommends using a [managed Redis installation](https://docs.seqera.io/platform-enterprise/enterprise/kubernetes#managed-redis-services) provided by an external provider, but [local Redis installations](https://docs.seqera.io/platform-enterprise/enterprise/kubernetes#deploy-a-redis-manifest-to-your-cluster) are also supported.
Either specify the Redis host in the `.global.redis` section to share it between multiple charts, or specify it below in the `.redis` section. If mixing locations, you must define the database that Redis will need for each product to use in `.redis.prefix`.
Values in the `.redis` section take precedence over values in the `.global.redis` section.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/platform --version 0.17.1 --namespace my-namespace --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/platform

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platformExternalDomain | string | `"example.com"` | Domain where Seqera Platform (formerly known as Tower) listens |
| global.contentDomain | string | `"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"` | Domain where user-created Platform reports are exposed, to avoid Cross-Site Scripting (XSS) attacks. If unset, data is served through the main domain .global.platformExternalDomain. Evaluated as a template |
| global.platformServiceAddress | string | `"{{ printf \"%s-backend\" (include \"common.names.fullname\" .) }}"` | Seqera Platform Service name: can be the internal Kubernetes hostname or an external ingress hostname. Evaluated as a template |
| global.platformServicePort | int | `8080` | Seqera Platform Service port |
| global.platformDatabase.host | string | `""` | Platform MySQL database hostname |
| global.platformDatabase.port | int | `3306` | Platform MySQL database port |
| global.platformDatabase.database | string | `""` | Platform MySQL database name |
| global.platformDatabase.username | string | `""` | Platform MySQL database username |
| global.platformDatabase.password | string | `""` | Platform MySQL database password |
| global.platformDatabase.existingSecretName | string | `""` | Name of an existing secret containing credentials for the Platform MySQL database Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| global.platformDatabase.existingSecretKey | string | `"TOWER_DB_PASSWORD"` | Key in the existing secret containing the password for the Platform MySQL database |
| global.platformDatabase.driver | string | `"mariadb"` | Database driver. Possible options: "mariadb" (or its alias "mysql"). |
| global.platformDatabase.connectionOptions | object | `{"mariadb":["permitMysqlScheme=true"]}` | Connection options to compose in the driver URL according to the driver used. The only driver that can be set is 'mariadb'. |
| global.platformDatabase.connectionOptions.mariadb | list | `["permitMysqlScheme=true"]` | Connection options to use with the MariaDB driver. For the full list of supported options see: https://mariadb.com/docs/connectors/mariadb-connector-j/about-mariadb-connector-j |
| global.platformDatabase.dialect | string | `"mysql-8"` | Hibernate dialect to use, depending on the database version. Possible options: mysql-8 (default), mariadb-10. |
| global.platformDatabase.minPoolSize | string | `"2"` | Connection pool minimum size. |
| global.platformDatabase.maxPoolSize | string | `"10"` | Connection pool maximum size. |
| global.platformDatabase.maxLifetime | string | `"180000"` | Connection pool maximum lifetime. |
| global.redis.host | string | `""` | Redis hostname |
| global.redis.port | int | `6379` | Redis port |
| global.redis.password | string | `""` | Redis password if the installation requires it |
| global.redis.existingSecretName | string | `""` | Name of an existing secret containing credentials for Redis, as an alternative to the password field. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| global.redis.existingSecretKey | string | `"TOWER_REDIS_PASSWORD"` | Key in the existing secret containing the password for Redis |
| global.redis.enableTls | bool | `false` | Enable TLS when connecting to Redis |
| global.imageCredentials | list | `[]` | Define credentials to log in and fetch images from a private registry  - registry: ""   username: ""   password: ""   email: someone@example.com  # Optional |
| platform.YAMLConfigFileContent | string | `""` | Content to insert into the tower.yml file (you can use `\|-` YAML multilines). See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview |
| platform.contactEmail | string | `"support@example.com"` | Sender email address for user support |
| platform.jwtSeedString | string | `""` | JWT seed, defined as string, used to sign authentication tokens Define the value as a String or a Secret, not both at the same time If neither is defined, Helm generates a random 35-character string |
| platform.jwtSeedSecretName | string | `""` | Name of an existing Secret containing the JWT seed. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| platform.jwtSeedSecretKey | string | `"TOWER_JWT_SECRET"` | Key in the existing secret containing the JWT seed |
| platform.cryptoSeedString | string | `""` | Crypto seed, defined as string, used to encrypt sensitive data in the database. Note: this needs to be a stable value that doesn't change between deployments, otherwise encrypted data in the database will become inaccessible. Either define the value as a String or a Secret, not both at the same time. If neither is defined, a random 35 characters long string will be generated by Helm. |
| platform.cryptoSeedSecretName | string | `""` | Name of an existing Secret containing the crypto seed. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| platform.cryptoSeedSecretKey | string | `"TOWER_CRYPTO_SECRETKEY"` | Key in the existing secret containing the crypto seed |
| platform.executionBackends | list | `["altair-platform","awsbatch-platform","awscloud-platform","azbatch-platform","eks-platform","gke-platform","googlebatch-platform","googlecloud-platform","k8s-platform","local-platform","lsf-platform","moab-platform","slurm-platform"]` | List of execution backends to enable. At least one is required. See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview#compute-environments |
| platform.licenseString | string | `""` | Platform license key. A license key is a long alphanumeric string provided by your Seqera account manager Define the value as a String or a Secret, not both at the same time |
| platform.licenseSecretName | string | `""` | Name of an existing Secret containing the Platform license key. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| platform.licenseSecretKey | string | `"TOWER_LICENSE"` | Key in the existing secret containing the Platform license key |
| platform.smtp.host | string | `""` | SMTP server hostname to let users authenticate through email, and to send email notifications for events |
| platform.smtp.port | string | `""` | SMTP server port |
| platform.smtp.user | string | `""` | SMTP server username |
| platform.smtp.password | string | `""` | SMTP server password |
| platform.smtp.existingSecretName | string | `""` | Name of an existing secret containing the SMTP password |
| platform.smtp.existingSecretKey | string | `"TOWER_SMTP_PASSWORD"` | Key in the existing secret containing the SMTP password |
| platform.waveServerUrl | string | `"https://wave.seqera.io"` | URL of the Wave service Platform uses (evaluated as template) The Wave service provided by Seqera is 'https://wave.seqera.io' |
| platform.configMapLabels | object | `{}` | Additional labels for the ConfigMap objects. Evaluated as a template |
| platform.secretLabels | object | `{}` | Additional labels for the Secret objects. Evaluated as a template |
| platform.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template |
| platform.configMapAnnotations | object | `{}` | Additional annotations for the ConfigMap objects. Evaluated as a template |
| platform.secretAnnotations | object | `{}` | Additional annotations for the Secret objects. Evaluated as a template |
| platform.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template |
| redis.host | string | `""` | Redis hostname |
| redis.port | int | `6379` | Redis port |
| redis.password | string | `""` | Redis password if the installation requires it |
| redis.existingSecretName | string | `""` | Name of an existing secret containing credentials for Redis, as an alternative to the password field. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time |
| redis.existingSecretKey | string | `"TOWER_REDIS_PASSWORD"` | Key in the existing secret containing the password for Redis |
| redis.enableTls | bool | `false` | Enable TLS when connecting to Redis |
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release  extraDeploy:   - apiVersion: v1     kind: MyExtraObjectKind     ...   - apiVersion: v1     kind: AnotherExtraObjectKind     ... |
| commonAnnotations | object | `{}` | Annotations to add to all deployed objects |
| commonLabels | object | `{}` | Labels to add to all deployed objects |
| backend.image.registry | string | `"cr.seqera.io"` | Backend container image registry |
| backend.image.repository | string | `"private/nf-tower-enterprise/backend"` | Backend container image repository |
| backend.image.tag | string | `"{{ .chart.AppVersion }}"` | Backend container image tag |
| backend.image.digest | string | `""` | Backend container image digest in the format 'sha256:1234abcdef' |
| backend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the backend container Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| backend.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| backend.micronautEnvironments | list | `["prod","redis","ha"]` | List of Micronaut Environments to enable on the backend pod |
| backend.service.type | string | `"ClusterIP"` | Backend Service type Note: ingresses using AWS ALB require the service to be NodePort |
| backend.service.http.name | string | `"http"` | Service name to use |
| backend.service.http.targetPort | int | `8080` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). Platform v25.3+ only; previous versions were hardcoded to 8080 |
| backend.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| backend.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  extraServices: - name: myspecialservice   port: 1234   targetPort: 5678   # nodePort is only used when service.type is Nodeport or LoadBalancer   # To set explicitly, choose port between 30000-32767 (unless your cluster was configured differently)   nodePort: "" |
| backend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| backend.initContainers | list | `[]` | Additional init containers for the backend pod. Evaluated as a template. |
| backend.command | list | `[]` | Override default container command (useful when using custom images). |
| backend.args | list | `[]` | Override default container args (useful when using custom images). |
| backend.podLabels | object | `{}` | Additional labels for the backend pod. Evaluated as a template. |
| backend.podAnnotations | object | `{}` | Additional annotations to apply to the pods (e.g. Prometheus, etc). Evaluated as a template. |
| backend.extraOptionsSpec | object | `{"replicas":3}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template.  extraOptionsSpec:   replicas: 2   strategy:     rollingUpdate:       maxUnavailable: x       maxSurge: y |
| backend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template.  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| backend.extraEnvVars | list | `[]` | Extra environment variables to set on the backend pod.  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| backend.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars. |
| backend.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars. |
| backend.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts`. |
| backend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes`. |
| backend.podSecurityContext.enabled | bool | `true` | Enable pod Security Context. |
| backend.podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access. |
| backend.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| backend.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| backend.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0). |
| backend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering. |
| backend.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container. |
| backend.resources | object | `{}` | Set container requests and limits for different resources like CPU or memory. .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ We usually recommend not to specify default resources and to leave this as a conscious choice for the user.  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
| backend.startupProbe.enabled | bool | `false` | Enable startup probe. |
| backend.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe. |
| backend.startupProbe.httpGet.port | int | `8080` | HTTP GET port for startup probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| backend.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps. |
| backend.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting. |
| backend.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses. |
| backend.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts). |
| backend.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness. |
| backend.readinessProbe.enabled | bool | `true` | Enable readiness probe. |
| backend.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe. |
| backend.readinessProbe.httpGet.port | int | `8080` | HTTP GET port for readiness probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| backend.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| backend.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation. |
| backend.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness. |
| backend.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart). |
| backend.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures. |
| backend.livenessProbe.enabled | bool | `true` | Enable liveness probe. |
| backend.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe. |
| backend.livenessProbe.httpGet.port | int | `8080` | HTTP GET port for liveness probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| backend.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| backend.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation. |
| backend.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly. |
| backend.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container. |
| backend.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored). |
| frontend.image.registry | string | `"cr.seqera.io"` | Frontend container image registry |
| frontend.image.repository | string | `"private/nf-tower-enterprise/frontend"` | Frontend container image repository |
| frontend.image.tag | string | `"{{ .chart.AppVersion }}-unprivileged"` | Specify a tag to override the version defined in .Chart.appVersion |
| frontend.image.digest | string | `""` | Frontend container image digest in the format 'sha256:1234abcdef' |
| frontend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the frontend container Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| frontend.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| frontend.service.type | string | `"ClusterIP"` | Frontend Service type Note: ingresses using AWS ALB require the service to be NodePort |
| frontend.service.http.name | string | `"http"` | Service name to use |
| frontend.service.http.port | int | `80` | Service port |
| frontend.service.http.targetPort | int | `8083` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| frontend.service.http.nodePort | int | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| frontend.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  extraServices: - name: myspecialservice   port: 1234   targetPort: 5678   # nodePort is only used when service.type is Nodeport or LoadBalancer   # To set explicitly, choose port between 30000-32767 (unless your cluster was configured differently)   nodePort: "" |
| frontend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| frontend.initContainers | list | `[]` | Additional init containers for the frontend pod. Evaluated as a template |
| frontend.command | list | `[]` | Override default container command (useful when using custom images) |
| frontend.args | list | `[]` | Override default container args (useful when using custom images) |
| frontend.podLabels | object | `{}` | Additional labels for the frontend pod. Evaluated as a template |
| frontend.podAnnotations | object | `{}` | Additional annotations to apply to the pods (for example, Prometheus). Evaluated as a template |
| frontend.extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. revisionHistoryLimit, etc). Evaluated as a template. Note: the cron deployment can only run a single replica and use Recreate strategy.  extraOptionsSpec:   replicas: 2   strategy:     rollingUpdate:       maxUnavailable: x       maxSurge: y |
| frontend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy) Evaluated as a template  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| frontend.extraEnvVars | list | `[]` | Extra environment variables to set on the frontend pod  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| frontend.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| frontend.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| frontend.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting extraVolumeMounts |
| frontend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with extraVolumes |
| frontend.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| frontend.podSecurityContext.fsGroup | int | `101` | GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access |
| frontend.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| frontend.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| frontend.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| frontend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| frontend.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| frontend.resources | object | `{}` | Container requests and limits for different resources like CPU or memory .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends not to specify default resources and to leave this as a conscious choice for the user  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
| frontend.startupProbe.enabled | bool | `false` | Enable startup probe |
| frontend.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe |
| frontend.startupProbe.httpGet.port | int | `8080` | HTTP GET port for startup probe. Evaluated as a template. Note: hardcoded to 8080 for now |
| frontend.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps |
| frontend.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting |
| frontend.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses |
| frontend.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts) |
| frontend.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness |
| frontend.readinessProbe.enabled | bool | `true` | Enable readiness probe |
| frontend.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe |
| frontend.readinessProbe.httpGet.port | int | `8080` | HTTP GET port for readiness probe. Evaluated as a template. Note: hardcoded to 8080 for now |
| frontend.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| frontend.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation |
| frontend.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness |
| frontend.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart) |
| frontend.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures |
| frontend.livenessProbe.enabled | bool | `true` | Enable liveness probe |
| frontend.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe |
| frontend.livenessProbe.httpGet.port | int | `8080` | HTTP GET port for liveness probe. Evaluated as a template. Note: hardcoded to 8080 for now |
| frontend.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing) |
| frontend.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation |
| frontend.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly |
| frontend.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container |
| frontend.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored) |
| cron.image.registry | string | `"cr.seqera.io"` | Cron container image registry |
| cron.image.repository | string | `"private/nf-tower-enterprise/backend"` | Cron container image repository |
| cron.image.tag | string | `"{{ .chart.AppVersion }}"` | Cron container image tag |
| cron.image.digest | string | `""` | Cron container image digest in the format 'sha256:1234abcdef' |
| cron.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the cron container Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| cron.micronautEnvironments | list | `["prod","redis","cron"]` | List of Micronaut Environments to enable on the cron pod |
| cron.service.type | string | `"ClusterIP"` | Cron Service type Note: ingresses using AWS ALB require the service to be NodePort |
| cron.service.http.name | string | `"http"` | Service name to use |
| cron.service.http.port | int | `8080` | Service port |
| cron.service.http.targetPort | int | `8082` | Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port) |
| cron.service.http.nodePort | string | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default |
| cron.service.extraServices | list | `[]` | Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  extraServices: - name: myspecialservice   port: 1234   targetPort: 5678   # nodePort is only used when service.type is Nodeport or LoadBalancer   # To set explicitly, choose port between 30000-32767 (unless your cluster was configured differently)   nodePort: "" |
| cron.service.extraOptions | object | `{}` | Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template |
| cron.initContainers | list | `[]` | Additional init containers for the cron pod. Evaluated as a template |
| cron.command | list | `[]` | Override default container command (useful when using custom images) |
| cron.args | list | `[]` | Override default container args (useful when using custom images) |
| cron.podLabels | object | `{}` | Additional labels for the cron pod. Evaluated as a template |
| cron.podAnnotations | object | `{}` | Additional annotations to apply to the pods (for example, Prometheus). Evaluated as a template |
| cron.extraOptionsSpec | object | `{}` | Extra options to place under .spec (for example, revisionHistoryLimit). Evaluated as a template Note that cron deployment needs to have a single replica with Recreate strategy  extraOptionsSpec:   revisionHistoryLimit: 4 |
| cron.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy) Evaluated as a template  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| cron.extraEnvVars | list | `[]` | Extra environment variables to set on the cron pod  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| cron.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| cron.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| cron.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting extraVolumeMounts |
| cron.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with extraVolumes |
| cron.podSecurityContext.enabled | bool | `true` | Enable pod Security Context |
| cron.podSecurityContext.fsGroup | int | `101` | GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access |
| cron.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| cron.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| cron.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| cron.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| cron.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| cron.resources | object | `{}` | Container requests and limits for different resources like CPU or memory .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends not to specify default resources and to leave this as a conscious choice for the user  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
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
| cron.dbMigrationInitContainer.image.registry | string | `"cr.seqera.io"` | Database migration container image registry |
| cron.dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/migrate-db"` | Database migration container image repository |
| cron.dbMigrationInitContainer.image.tag | string | `"{{ .chart.AppVersion }}"` | Specify a tag to override the version defined in .Chart.appVersion |
| cron.dbMigrationInitContainer.image.digest | string | `""` | Database migration container image digest in the format 'sha256:1234abcdef' |
| cron.dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the database migration init container Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.dbMigrationInitContainer.image.pullSecrets | list | `[]` | List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| cron.dbMigrationInitContainer.command | list | `["/bin/sh","-c","/migrate-db.sh"]` | Override default container command (useful when using custom images) |
| cron.dbMigrationInitContainer.args | list | `[]` | Override default container args (useful when using custom images) |
| cron.dbMigrationInitContainer.extraEnvVars | list | `[]` | Extra environment variables to set on the cron pod  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| cron.dbMigrationInitContainer.extraEnvVarsCMs | list | `[]` | ConfigMap containing extra env vars |
| cron.dbMigrationInitContainer.extraEnvVarsSecrets | list | `[]` | Secret containing extra env vars |
| cron.dbMigrationInitContainer.extraVolumes | list | `[]` | Extra volumes to add to the deployment (evaluated as template). Requires setting extraVolumeMounts |
| cron.dbMigrationInitContainer.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with extraVolumes |
| cron.dbMigrationInitContainer.containerSecurityContext.enabled | bool | `true` | Enable container Security Context |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsUser | int | `101` | UID the container processes run as (overrides container image default) |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root UID (prevents starting if UID 0) |
| cron.dbMigrationInitContainer.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the container root filesystem read-only to prevent in-place writes or tampering |
| cron.dbMigrationInitContainer.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container |
| cron.dbMigrationInitContainer.resources | object | `{}` | Container requests and limits for different resources like CPU or memory .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends not to specify default resources and to leave this as a conscious choice for the user  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
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
| serviceAccount.name | string | `""` | Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated |
| serviceAccount.annotations | object | `{}` | Additional annotations for the Tower ServiceAccount to generate |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries |
| serviceAccount.automountServiceAccountToken | bool | `false` | Automount service account token when the server service account is generated |
| ingress.enabled | bool | `false` | Enable ingress for Platform |
| ingress.path | string | `"/"` | Path for the main ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller |
| ingress.contentPath | string | `"/"` | Path for the content domain ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller |
| ingress.defaultPathType | string | `"ImplementationSpecific"` | Default path type for the Ingress |
| ingress.defaultBackend | object | `{}` | Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems  defaultBackend:   service:     name: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'     port:       number: '{{ .Values.frontend.service.http.port }}' |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template  extraHosts:   - host: '{{ printf "api.%s" .Values.global.platformExternalDomain }}'     paths:       - path: /*  # For ALB ingress controller         pathType: Prefix  # Optional, defaults to defaultPathType value         serviceName: '{{ printf "%s-backend" (include "common.names.fullname" .) }}'         portNumber: '{{ .Values.global.platformServicePort }}'   - host: '{{ printf "www.%s" .Values.global.platformExternalDomain }}'     paths:       - path: /*  # For ALB ingress controller         pathType: Prefix  # Optional, defaults to defaultPathType value         serviceName: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'         portNumber: '{{ .Values.frontend.service.http.port }}' |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces deprecated annotation 'kubernetes.io/ingress.class') |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template.  tls:   - hosts:       - '{{ .Values.global.platformExternalDomain }}'       - '{{ printf "user-data.%s" .Values.global.platformExternalDomain }}'     secretName: my-tls |
