# platform

A Helm chart to deploy Seqera Platform (formerly known as Tower) on Kubernetes.

![Version: 0.13.0](https://img.shields.io/badge/Version-0.13.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.2.3](https://img.shields.io/badge/AppVersion-v25.2.3-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements

- Kubernetes 1.19+
- Helm 3+
- MySQL database
- Redis v7-compatible cache

## Platform architecture

The [Seqera Platform architecture](https://docs.seqera.io/platform-enterprise/enterprise/overview)
consists of the following components:

- Backend
  * The backend app is the main application server, exposing the REST API and handling most of the
    business logic.
- Cron pod
  * The cron app is needed to perform certain async operations on the database and on the
    environment (CE environment creation, etc). For this reason there can only be one at a time, and
    it's a separate deployment and not a sidecar deployment of the backend deployment.
- Frontend pod
  * The frontend app is a separate deployment serving the web UI.
- MySQL database
  * The MySQL database is required to store all the Platform data.
- Redis cache
  * The Redis cache is required for caching and for managing async jobs.

### Redis Cache details

Multiple Seqera products require a Redis cache. Seqera recommends using a managed Redis installation
provided by an external provider, but a local Redis installation is supported.
Either specify the Redis host in the `.global.redis` section to share it between multiple charts and
other charts, or specify it below in the `.redis` section: if mixing locations, remember to define
the database that Redis will need for each product to use in `.redis.prefix`.
Values in the `.redis` section take precedence over values in the `.global.redis` section.

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm repo add example http://charts.example.com
$ helm install my-release example/platform
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platformExternalDomain | string | `"example.com"` | Optional domain where Seqera Platform (formerly known as Tower) will listen on. |
| global.contentDomain | string | `"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"` | Domain where user-created Platform reports are exposed at (evaluated as template), to avoid Cross-Site Scripting attacks. If unset, data will be served through the main domain .global.platformExternalDomain. Evaluated as a template. |
| global.platformServiceAddress | string | `"{{ printf \"%s-backend\" (include \"common.names.fullname\" .) }}"` | Seqera Platform Service name: can be the internal kubernetes hostname or an external ingress hostname. Evaluated as a template. |
| global.platformServicePort | int | `8080` | Seqera Platform Service port. |
| global.platformDatabase.host | string | `""` | Platform MySQL database hostname. |
| global.platformDatabase.port | int | `3306` | Platform MySQL database port. |
| global.platformDatabase.database | string | `""` | Platform MySQL database name. |
| global.platformDatabase.username | string | `""` | Platform MySQL database username. |
| global.platformDatabase.password | string | `""` | Platform MySQL database password. |
| global.platformDatabase.existingSecretName | string | `""` | Name of an existing secret containing credentials for the Platform MySQL db. |
| global.platformDatabase.existingSecretKey | string | `"TOWER_DB_PASSWORD"` | Key in the existing secret containing the password for the Platform MySQL db. |
| global.platformDatabase.driver | string | `"org.mariadb.jdbc.Driver"` | JDBC driver class name. |
| global.platformDatabase.dialect | string | `"io.seqera.util.MySQL55DialectCollateBin"` | Hibernate dialect to use. |
| global.platformDatabase.minPoolSize | string | `"0"` | Connection pool minimum size. |
| global.platformDatabase.maxPoolSize | string | `"5"` | Connection pool maximum size. |
| global.platformDatabase.maxLifetime | string | `"60000"` | Connection pool maximum lifetime. |
| global.redis.host | string | `""` | Redis hostname. |
| global.redis.port | int | `6379` | Redis port. |
| global.redis.auth.enabled | bool | `false` | Enable Redis authentication. |
| global.redis.auth.password | string | `""` | Redis authentication password. |
| global.redis.auth.existingSecretName | string | `""` | Name of an existing secret containing credentials for Redis. |
| global.redis.auth.existingSecretKey | string | `"TOWER_REDIS_PASSWORD"` | Key in the existing secret containing the password for Redis. |
| global.redis.tls.enabled | bool | `false` | Enable TLS when connecting to Redis. |
| global.imageCredentials | list | `[]` | Optionally define credentials to login and fetch images from a private registry.  - registry: ""   username: ""   password: ""   email: someone@example.com  # Optional. |
| platform.YAMLConfigFileContent | string | `""` | Content to insert into the tower.yml file (you can use `\|-` YAML multilines). See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview |
| platform.contactEmail | string | `"support@example.com"` | Sender email address for user support. |
| platform.jwtSeedString | string | `""` | JWT seed, defined as string. It is used to sign authentication tokens. Either define the value as a String or a Secret, not both at the same time. If neither is defined, a random 35 characters long string will be generated by Helm. |
| platform.jwtSeedSecretName | string | `""` | Name of the Secret containing the JWT seed. |
| platform.jwtSeedSecretKey | string | `"TOWER_JWT_SECRET"` | Key in the existing secret containing the JWT seed. |
| platform.cryptoSeedString | string | `""` | Crypto seed, defined as string. It is used to encrypt sensitive data in the database. Either define the value as a String or a Secret, not both at the same time. If neither is defined, a random 35 characters long string will be generated by Helm. |
| platform.cryptoSeedSecretName | string | `""` | Name of the Secret containing the crypto seed. |
| platform.cryptoSeedSecretKey | string | `"TOWER_CRYPTO_SECRETKEY"` | Key in the existing secret containing the crypto seed. |
| platform.executionBackends | list | `["altair-platform","awsbatch-platform","awscloud-platform","azbatch-platform","eks-platform","gke-platform","googlebatch-platform","googlecloud-platform","k8s-platform","local-platform","lsf-platform","moab-platform","slurm-platform"]` | List of execution backends to enable. At least one is required. See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview#configuration-values-not-supported-in-toweryml-or-aws-parameter-store |
| platform.flywayLocations | string | `"classpath:db-schema/mysql"` |  |
| platform.licenseString | string | `""` | Platform license key. A license key is a long alphanumeric string provided by your Seqera Labs account manager. Either define the value as a String or a Secret, not both at the same time. |
| platform.licenseSecretName | string | `""` | Name of the Secret containing the Platform license key. |
| platform.licenseSecretKey | string | `"TOWER_LICENSE"` | Key in the existing secret containing the Platform license key. |
| platform.smtp.host | string | `""` | SMTP server hostname to let users authenticate through email, and to send email notifications for events. |
| platform.smtp.port | string | `""` | SMTP server port. |
| platform.smtp.user | string | `""` | SMTP server username. |
| platform.smtp.password | string | `""` | SMTP server password. |
| platform.smtp.existingSecretName | string | `""` | Name of an existing secret containing the SMTP password. |
| platform.smtp.existingSecretKey | string | `"TOWER_SMTP_PASSWORD"` | Key in the existing secret containing the SMTP password. |
| platform.awsSesEnable | bool | `false` | Use AWS Simple Email Service (SES) to send Seqera emails instead of SMTP. An IAM role with the appropriate permissions needs to be exposed to the cron pod, e.g. via IRSA, EKS Pod Identity, etc. |
| platform.waveServerUrl | string | `"https://wave.seqera.io"` | URL of the Wave service Platform needs to use (evaluated as template). The Wave service provided by Seqera is 'https://wave.seqera.io'. |
| platform.configMapLabels | object | `{}` | Additional labels for the ConfigMap objects. Evaluated as a template. |
| platform.secretLabels | object | `{}` | Additional labels for the Secret objects. Evaluated as a template. |
| platform.serviceLabels | object | `{}` | Additional labels for the Service objects. Evaluated as a template. |
| platform.configMapAnnotations | object | `{}` | Additional annotations for the ConfigMap objects. Evaluated as a template. |
| platform.secretAnnotations | object | `{}` | Additional annotations for the Secret objects. Evaluated as a template. |
| platform.serviceAnnotations | object | `{}` | Additional annotations for the Service objects. Evaluated as a template. |
| redis.host | string | `""` | Redis hostname. |
| redis.port | int | `6379` | Redis port. |
| redis.auth.enabled | bool | `false` | Enable Redis authentication. |
| redis.auth.password | string | `""` | Redis authentication password. |
| redis.auth.existingSecretName | string | `""` | Name of an existing secret containing credentials for Redis. |
| redis.auth.existingSecretKey | string | `"TOWER_REDIS_PASSWORD"` | Key in the existing secret containing the password for Redis. |
| redis.tls.enabled | bool | `false` | Enable TLS when connecting to Redis. |
| redis.prefix | string | `""` | Prefix for the Redis database to use. |
| extraDeploy | list | `[]` | Array of extra objects to deploy with the release.  extraDeploy:   - apiVersion: v1     kind: MyExtraObjectKind     ...   - apiVersion: v1     kind: AnotherExtraObjectKind     ... |
| commonAnnotations | object | `{}` | Annotations to add to all deployed objects. |
| commonLabels | object | `{}` | Labels to add to all deployed objects. |
| backend.image.registry | string | `"cr.seqera.io"` | Backend container image registry. |
| backend.image.repository | string | `"private/nf-tower-enterprise/backend"` | Backend container image repository. |
| backend.image.tag | string | {{ .chart.AppVersion }} | Backend container image tag. |
| backend.image.digest | string | `""` | Backend container image digest in the format 'sha256:1234abcdef'. |
| backend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the backend container. Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent'. Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| backend.image.pullSecrets | list | `[]` | Optional list of imagePullSecrets. Secrets must be already created in the same namespace, e.g. with the extraDeploy array above. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| backend.micronautEnvironments | list | `["prod","redis","ha"]` | List of Micronaut Environments to enable on the backend pod. |
| backend.service.type | string | `"ClusterIP"` | Backend Service type. Note: ingresses using AWS ALB require the service to be NodePort. |
| backend.service.http.name | string | `"http"` | Service name to use. |
| backend.service.http.nodePort | int | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer. Choose port between 30000-32767, unless the cluster was configured differently than default. |
| backend.service.extraServices | list | `[{"name":"jmx","port":1099,"targetPort":1099}]` | Other services that should live in the Service object. https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service |
| backend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (e.g. clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs, etc). Evaluated as a template. |
| backend.initContainers | list | `[]` | Additional init containers for the backend pod. Evaluated as a template. |
| backend.command | list | `[]` | Override default container command (useful when using custom images). |
| backend.args | list | `[]` | Override default container args (useful when using custom images). |
| backend.podLabels | object | `{}` | Additional labels for the backend pod. Evaluated as a template. |
| backend.podAnnotations | object | `{}` | Additional annotations to apply to the pods (e.g. Prometheus, etc). Evaluated as a template. |
| backend.extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template.  extraOptionsSpec:   replicas: 2   strategy:     rollingUpdate:       maxUnavailable: x       maxSurge: y |
| backend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template.  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| backend.extraEnvVars | list | `[]` | Extra environment variables to set on the backend pod.  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| backend.extraEnvVarsCM | string | `""` | ConfigMap containing extra env vars. |
| backend.extraEnvVarsSecret | string | `""` | Secret containing extra env vars. |
| backend.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts`. |
| backend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes`. |
| backend.podSecurityContext.enabled | bool | `true` | Enable backend pods Security Context. |
| backend.podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access. |
| backend.containerSecurityContext.enabled | bool | `true` | Enable backend containers Security Context |
| backend.containerSecurityContext.runAsUser | int | `101` | Specifies the numeric UID the container processes should run as (overrides container image default). |
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
| frontend.image.registry | string | `"cr.seqera.io"` | Frontend container image registry. |
| frontend.image.repository | string | `"private/nf-tower-enterprise/frontend"` | Frontend container image repository. |
| frontend.image.tag | string | {{ .chart.AppVersion }}-unprivileged | Specify a tag to override the version defined in .Chart.appVersion. |
| frontend.image.digest | string | `""` | Frontend container image digest in the format 'sha256:1234abcdef'. |
| frontend.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the frontend container. Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| frontend.image.pullSecrets | list | `[]` | Optional list of imagePullSecrets. Secrets must be manually created in the same namespace. See the extraDeploy array above. ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| frontend.service.type | string | `"ClusterIP"` | Frontend Service type. Note: ingresses using AWS ALB require the service to be NodePort. |
| frontend.service.http.name | string | `"http"` | Service name to use. |
| frontend.service.http.port | int | `80` | Service port. |
| frontend.service.http.targetPort | int | `8083` | The port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). |
| frontend.service.http.nodePort | int | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer. Choose port between 30000-32767, unless the cluster was configured differently than default. |
| frontend.service.extraServices | list | `[]` | Other services that should live in the Service object. https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  extraServices: - name: myspecialservice   port: 1234   targetPort: 5678 |
| frontend.service.extraOptions | object | `{}` | Extra Service options to place under .spec (e.g. clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs, etc). Evaluated as a template. |
| frontend.initContainers | list | `[]` |  |
| frontend.command | list | `[]` | Override default container command (useful when using custom images) |
| frontend.args | list | `[]` | Override default container args (useful when using custom images) |
| frontend.podLabels | object | `{}` | Additional labels for the frontend pod. Evaluated as a template. |
| frontend.podAnnotations | object | `{}` | Additional annotations to apply to the pods (e.g. Prometheus, etc). Evaluated as a template. |
| frontend.extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template.  extraOptionsSpec:   replicas: 2   strategy:     rollingUpdate:       maxUnavailable: x       maxSurge: y |
| frontend.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template.  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| frontend.extraEnvVars | list | `[]` | Extra environment variables to set on the frontend pod.  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| frontend.extraEnvVarsCM | string | `""` | ConfigMap containing extra env vars. |
| frontend.extraEnvVarsSecret | string | `""` | Secret containing extra env vars. |
| frontend.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts`. |
| frontend.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes`. |
| frontend.podSecurityContext.enabled | bool | `true` | Enable backend pods Security Context. |
| frontend.podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access. |
| frontend.containerSecurityContext.enabled | bool | `true` | Enable backend containers Security Context |
| frontend.containerSecurityContext.runAsUser | int | `101` | Specifies the numeric UID the container processes should run as (overrides container image default). |
| frontend.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0). |
| frontend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering. |
| frontend.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container. |
| frontend.resources | object | `{}` | Set container requests and limits for different resources like CPU or memory. .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ We usually recommend not to specify default resources and to leave this as a conscious choice for the user.  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
| frontend.startupProbe.enabled | bool | `false` | Enable startup probe. |
| frontend.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe. |
| frontend.startupProbe.httpGet.port | int | `8080` | HTTP GET port for startup probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| frontend.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps. |
| frontend.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting. |
| frontend.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses. |
| frontend.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts). |
| frontend.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness. |
| frontend.readinessProbe.enabled | bool | `true` | Enable readiness probe. |
| frontend.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe. |
| frontend.readinessProbe.httpGet.port | int | `8080` | HTTP GET port for readiness probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| frontend.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| frontend.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation. |
| frontend.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness. |
| frontend.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart). |
| frontend.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures. |
| frontend.livenessProbe.enabled | bool | `true` | Enable liveness probe. |
| frontend.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe. |
| frontend.livenessProbe.httpGet.port | int | `8080` | HTTP GET port for liveness probe. Evaluated as a template. Note: hardcoded to 8080 for now. |
| frontend.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| frontend.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation. |
| frontend.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly. |
| frontend.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container. |
| frontend.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored). |
| cron.image.registry | string | `"cr.seqera.io"` | Cron container image registry. |
| cron.image.repository | string | `"private/nf-tower-enterprise/backend"` | Cron container image repository. |
| cron.image.tag | string | {{ .chart.AppVersion }} | Cron container image tag. |
| cron.image.digest | string | `""` | Cron container image digest in the format 'sha256:1234abcdef'. |
| cron.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the cron container. Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.image.pullSecrets | list | `[]` | Optional list of imagePullSecrets. Secrets must be manually created in the same namespace. See the extraDeploy array above. Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| cron.micronautEnvironments | list | `["prod","redis","cron"]` | List of Micronaut Environments to enable on the cron pod. |
| cron.service.type | string | `"ClusterIP"` | Cron Service type. Note: ingresses using AWS ALB require the service to be NodePort. |
| cron.service.http.name | string | `"http"` | Service name to use. |
| cron.service.http.port | int | `8080` | Service port. |
| cron.service.http.targetPort | int | `8082` | The port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). |
| cron.service.http.nodePort | int | `nil` | Service node port, only used when service.type is Nodeport or LoadBalancer. Choose port between 30000-32767, unless the cluster was configured differently than default. |
| cron.service.extraServices | list | `[]` | Other services that should live in the Service object. https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  extraServices: - name: myspecialservice   port: 1234   targetPort: 5678 |
| cron.service.extraOptions | object | `{}` |  |
| cron.initContainers | list | `[]` | Additional init containers for the cron pod. Evaluated as a template. |
| cron.command | list | `[]` | Override default container command (useful when using custom images). |
| cron.args | list | `[]` | Override default container args (useful when using custom images). |
| cron.podLabels | object | `{}` | Additional labels for the cron pod. Evaluated as a template. |
| cron.podAnnotations | object | `{}` | Additional annotations to apply to the pods (e.g. Prometheus, etc). Evaluated as a template. |
| cron.extraOptionsSpec | object | `{}` | Extra options to place under .spec (e.g. revisionHistoryLimit, etc). Evaluated as a template. Note that cron deployment needs to have a single replica with Recreate strategy.  extraOptionsSpec:   revisionHistoryLimit: 4 |
| cron.extraOptionsTemplateSpec | object | `{}` | Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template.  extraOptionsTemplateSpec:   nodeSelector:     service: myspecialnodegroup |
| cron.extraEnvVars | list | `[]` | Extra environment variables to set on the cron pod.  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| cron.extraEnvVarsCM | string | `""` | ConfigMap containing extra env vars. |
| cron.extraEnvVarsSecret | string | `""` | Secret containing extra env vars. |
| cron.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts`. |
| cron.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes`. |
| cron.podSecurityContext.enabled | bool | `true` | Enable backend pods Security Context. |
| cron.podSecurityContext.fsGroup | int | `101` | Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access. |
| cron.containerSecurityContext.enabled | bool | `true` | Enable backend containers Security Context |
| cron.containerSecurityContext.runAsUser | int | `101` | Specifies the numeric UID the container processes should run as (overrides container image default). |
| cron.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0). |
| cron.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering. |
| cron.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container. |
| cron.resources | object | `{}` | Set container requests and limits for different resources like CPU or memory. .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ We usually recommend not to specify default resources and to leave this as a conscious choice for the user.  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
| cron.startupProbe.enabled | bool | `false` | Enable startup probe. |
| cron.startupProbe.httpGet.path | string | `"/health"` | HTTP GET path for startup probe. |
| cron.startupProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for startup probe. Evaluated as a template. |
| cron.startupProbe.initialDelaySeconds | int | `5` | Longer initial wait to accommodate slow-starting apps. |
| cron.startupProbe.periodSeconds | int | `10` | Often set longer to avoid frequent checks while starting. |
| cron.startupProbe.timeoutSeconds | int | `3` | Can be longer to allow slow initialization responses. |
| cron.startupProbe.failureThreshold | int | `5` | Consecutive failures during startup before killing the container (instead of immediate restarts). |
| cron.startupProbe.successThreshold | int | `1` | Number of consecutive successes required to consider startup complete and enable liveness/readiness. |
| cron.readinessProbe.enabled | bool | `true` | Enable readiness probe. |
| cron.readinessProbe.httpGet.path | string | `"/health"` | HTTP GET path for readiness probe. |
| cron.readinessProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for readiness probe. Evaluated as a template. |
| cron.readinessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| cron.readinessProbe.periodSeconds | int | `5` | Regular check interval during normal operation. |
| cron.readinessProbe.timeoutSeconds | int | `3` | Short timeout to detect unresponsive containers for readiness. |
| cron.readinessProbe.failureThreshold | int | `5` | Consecutive failures before marking the container Unready (no restart). |
| cron.readinessProbe.successThreshold | int | `1` | Number of consecutive successes required to mark the container Ready after failures. |
| cron.livenessProbe.enabled | bool | `true` | Enable liveness probe. |
| cron.livenessProbe.httpGet.path | string | `"/health"` | HTTP GET path for liveness probe. |
| cron.livenessProbe.httpGet.port | string | `"{{ .Values.cron.service.http.targetPort }}"` | HTTP GET port for liveness probe. Evaluated as a template. |
| cron.livenessProbe.initialDelaySeconds | int | `5` | Delay before first check (normal start timing). |
| cron.livenessProbe.periodSeconds | int | `10` | Regular check interval during normal operation. |
| cron.livenessProbe.timeoutSeconds | int | `3` | Short timeout to detect hung containers quickly. |
| cron.livenessProbe.failureThreshold | int | `10` | Consecutive failures before restarting the container. |
| cron.livenessProbe.successThreshold | int | `1` | Typically 1 (usually ignored). |
| cron.dbMigrationInitContainer.image.registry | string | `"cr.seqera.io"` | Database migration container image registry. |
| cron.dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/migrate-db"` | Database migration container image repository. |
| cron.dbMigrationInitContainer.image.tag | string | {{ .chart.AppVersion }} | Specify a tag to override the version defined in .Chart.appVersion. |
| cron.dbMigrationInitContainer.image.digest | string | `""` | Database migration container image digest in the format 'sha256:1234abcdef'. |
| cron.dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` | imagePullPolicy for the database migration init container. Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent' ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images |
| cron.dbMigrationInitContainer.image.pullSecrets | list | `[]` | Optional list of imagePullSecrets. Secrets must be manually created in the same namespace. See the extraDeploy array above. ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  pullSecrets:   - myRegistryKeySecretName |
| cron.dbMigrationInitContainer.extraEnvVars | list | `[]` | Extra environment variables to set on the frontend pod.  extraEnvVars:   - name: "MY_SPECIAL_ENVIRONMENT_VARIABLE"     value: "set-a-value-here" |
| cron.dbMigrationInitContainer.extraEnvVarsCM | string | `""` | ConfigMap containing extra env vars. |
| cron.dbMigrationInitContainer.extraEnvVarsSecret | string | `""` | Secret containing extra env vars. |
| cron.dbMigrationInitContainer.extraVolumes | list | `[]` | Extra volumes to be added to the deployment (evaluated as template). Requires setting `extraVolumeMounts`. |
| cron.dbMigrationInitContainer.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the container (evaluated as template). Normally used with `extraVolumes`. |
| cron.dbMigrationInitContainer.containerSecurityContext.enabled | bool | `true` | Enable backend containers Security Context |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsUser | int | `101` | Specifies the numeric UID the container processes should run as (overrides container image default). |
| cron.dbMigrationInitContainer.containerSecurityContext.runAsNonRoot | bool | `true` | Boolean that requires the container to run as a non-root UID (prevents starting if UID 0). |
| cron.dbMigrationInitContainer.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mounts the container root filesystem read-only to prevent in-place writes or tampering. |
| cron.dbMigrationInitContainer.containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Fine-grained Linux kernel privileges to add or drop for the container. |
| cron.dbMigrationInitContainer.resources | object | `{}` | Set container requests and limits for different resources like CPU or memory. .requests are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. .limits are the maximum resources a container is allowed to use. Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ We usually recommend not to specify default resources and to leave this as a conscious choice for the user.  requests:   requests:     cpu: "1"     memory: "1000Mi"   limits:     memory: "3000Mi" |
| initContainerDependencies.enabled | bool | `true` | Enable init containers that coordinate startup dependencies between Platform components (e.g., wait for database readiness before cron starts, wait for cron before backend starts). |
| initContainersUtils.waitForMySQLImage.registry | string | `""` |  |
| initContainersUtils.waitForMySQLImage.repository | string | `"mysql"` |  |
| initContainersUtils.waitForMySQLImage.tag | string | `"9"` |  |
| initContainersUtils.waitForMySQLImage.digest | string | `""` |  |
| initContainersUtils.waitForMySQLImage.pullPolicy | string | `"IfNotPresent"` |  |
| initContainersUtils.waitForRedisImage.registry | string | `""` |  |
| initContainersUtils.waitForRedisImage.repository | string | `"redis"` |  |
| initContainersUtils.waitForRedisImage.tag | string | `"7"` |  |
| initContainersUtils.waitForRedisImage.digest | string | `""` |  |
| initContainersUtils.waitForRedisImage.pullPolicy | string | `"IfNotPresent"` |  |
| initContainersUtils.waitForCronImage.registry | string | `""` |  |
| initContainersUtils.waitForCronImage.repository | string | `"curlimages/curl"` |  |
| initContainersUtils.waitForCronImage.tag | string | `"latest"` |  |
| initContainersUtils.waitForCronImage.digest | string | `""` |  |
| initContainersUtils.waitForCronImage.pullPolicy | string | `"IfNotPresent"` |  |
| serviceAccount.name | string | `""` | Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated. |
| serviceAccount.annotations | object | `{}` | Additional annotations for the Tower ServiceAccount to generate. |
| serviceAccount.imagePullSecretNames | list | `[]` | Names of Secrets containing credentials to pull images from registries. |
| serviceAccount.automountServiceAccountToken | bool | `false` | Whether to automount service account token when the server service account is generated. |
| ingress.enabled | bool | `false` | Enable ingress for Platform. |
| ingress.path | string | `"/"` | Path for the main ingress rule. Note: this needs to be set to '/*' to be used with AWS ALB ingress controller. |
| ingress.contentPath | string | `"/"` | Path for the content domain ingress rule. Note: this needs to be set to '/*' to be used with AWS ALB ingress controller. |
| ingress.defaultPathType | string | `"ImplementationSpecific"` | Default path type for the Ingress. |
| ingress.defaultBackend | object | `{}` | Optionally configure the default service for the ingress (evaluated as template). Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems.  defaultBackend:   service:     name: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'     port:       number: '{{ .Values.frontend.service.http.port }}' |
| ingress.extraHosts | list | `[]` | Additional hosts you want to include. Evaluated as a template.  extraHosts:   - host: '{{ printf "api.%s" .Values.global.platformExternalDomain }}'     paths:       - path: /*  # For ALB ingress controller         pathType: Prefix  # Optional, defaults to defaultPathType value         serviceName: '{{ printf "%s-backend" (include "common.names.fullname" .) }}'         portNumber: '{{ .Values.global.platformServicePort }}'   - host: '{{ printf "www.%s" .Values.global.platformExternalDomain }}'     paths:       - path: /*  # For ALB ingress controller         pathType: Prefix  # Optional, defaults to defaultPathType value         serviceName: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'         portNumber: '{{ .Values.frontend.service.http.port }}' |
| ingress.annotations | object | `{}` | Ingress annotations specific to your load balancer. Evaluated as a template. |
| ingress.extraLabels | object | `{}` | Additional labels for the ingress object. Evaluated as a template. |
| ingress.ingressClassName | string | `""` | Name of the ingress class (replaces deprecated annotation 'kubernetes.io/ingress.class'). |
| ingress.tls | list | `[]` | TLS configuration. Evaluated as a template. |
