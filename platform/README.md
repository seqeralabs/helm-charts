# platform

![Version: 0.11.1](https://img.shields.io/badge/Version-0.11.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.2.3](https://img.shields.io/badge/AppVersion-v25.2.3-informational?style=flat-square)

A Helm chart to deploy Seqera Platform (formerly known as Tower) on Kubernetes

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
| global.platformExternalDomain | string | `"example.com"` | Optional domain where Seqera Platform (formerly known as Tower) will listen on. |
| global.contentDomain | string | `"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"` | Domain where user-created Platform reports are exposed at (evaluated as template), to avoid Cross-Site Scripting attacks. If unset, data will be served through the main domain .global.platformExternalDomain. |
| global.apiDomain | string | `"{{ printf \"api.%s\" .Values.global.platformExternalDomain }}"` | Domain where to expose the API service (evaluated as template). This domain is mostly aesthetic, since Platform already listens to the API on ${.global.platformExternalDomain}/api/ and uses that internally. |
| global.platformServiceAddress | string | `"{{ printf \"%s-backend\" (include \"common.names.fullname\" .) }}"` | Seqera Platform Service name: can be the internal kubernetes hostname or an external ingress hostname. |
| global.platformServicePort | int | `8080` | Seqera Platform Service port. |
| global.platformDatabase.host | string | `""` | Platform MySQL database hostname. |
| global.platformDatabase.port | int | `3306` | Platform MySQL database port. |
| global.platformDatabase.database | string | `""` | Platform MySQL database name. |
| global.platformDatabase.username | string | `""` | Platform MySQL database username. |
| global.platformDatabase.password | string | `""` | Platform MySQL database password. |
| global.platformDatabase.existingSecretName | string | `""` | Name of an existing secret containing credentials for the Platform MySQL db. |
| global.platformDatabase.existingSecretKey | string | `"TOWER_DB_PASSWORD"` | Key in the existing secret containing the password for the Platform MySQL db. |
| global.redis.host | string | `""` |  |
| global.redis.port | int | `6379` |  |
| global.redis.auth.enabled | bool | `false` |  |
| global.redis.auth.password | string | `""` |  |
| global.redis.auth.existingSecretName | string | `""` |  |
| global.redis.auth.existingSecretKey | string | `""` |  |
| global.redis.tls.enabled | bool | `false` |  |
| global.imageCredentials | list | `[]` |  |
| tower.YAMLConfigFileContent | string | `""` |  |
| tower.contactEmail | string | `"tower-support@example.com"` |  |
| tower.jwtSeedString | string | `""` |  |
| tower.jwtSeedSecretName | string | `""` |  |
| tower.jwtSeedSecretKey | string | `""` |  |
| tower.cryptoSeedString | string | `""` |  |
| tower.cryptoSeedSecretName | string | `""` |  |
| tower.cryptoSeedSecretKey | string | `""` |  |
| tower.enablePlatforms | string | `"altair-platform,awsbatch-platform,azbatch-platform,eks-platform,googlebatch-platform,gke-platform,k8s-platform,lsf-platform,moab-platform,slurm-platform"` |  |
| tower.flywayLocations | string | `"classpath:db-schema/mysql"` |  |
| tower.licenseString | string | `""` |  |
| tower.licenseSecretName | string | `""` |  |
| tower.licenseSecretKey | string | `""` |  |
| tower.awsSesEnable | bool | `false` |  |
| tower.smtp.host | string | `""` |  |
| tower.smtp.port | string | `""` |  |
| tower.smtp.user | string | `""` |  |
| tower.smtp.password | string | `""` |  |
| tower.smtp.existingSecretName | string | `""` |  |
| tower.smtp.existingSecretKey | string | `""` |  |
| tower.db.driver | string | `"org.mariadb.jdbc.Driver"` |  |
| tower.db.dialect | string | `"io.seqera.util.MySQL55DialectCollateBin"` |  |
| tower.db.minPoolSize | string | `"0"` |  |
| tower.db.maxPoolSize | string | `"5"` |  |
| tower.db.maxLifetime | string | `"60000"` |  |
| tower.waveServerUrl | string | `"https://wave.seqera.io"` |  |
| tower.configMapLabels | object | `{}` |  |
| tower.secretLabels | object | `{}` |  |
| tower.serviceLabels | object | `{}` |  |
| tower.configMapAnnotations | object | `{}` |  |
| tower.secretAnnotations | object | `{}` |  |
| tower.serviceAnnotations | object | `{}` |  |
| redis.host | string | `""` |  |
| redis.port | int | `6379` |  |
| redis.auth.enabled | bool | `false` |  |
| redis.auth.password | string | `""` |  |
| redis.auth.existingSecretName | string | `""` |  |
| redis.auth.existingSecretKey | string | `""` |  |
| redis.tls.enabled | bool | `false` |  |
| redis.prefix | string | `""` |  |
| extraDeploy | list | `[]` |  |
| commonAnnotations | object | `{}` |  |
| commonLabels | object | `{}` |  |
| backend.image.registry | string | `"cr.seqera.io"` |  |
| backend.image.repository | string | `"private/nf-tower-enterprise/backend"` |  |
| backend.image.tag | string | `""` |  |
| backend.image.digest | string | `""` |  |
| backend.image.pullPolicy | string | `"IfNotPresent"` |  |
| backend.image.pullSecrets | list | `[]` |  |
| backend.micronautEnvironments[0] | string | `"prod"` |  |
| backend.micronautEnvironments[1] | string | `"redis"` |  |
| backend.micronautEnvironments[2] | string | `"ha"` |  |
| backend.service.type | string | `"ClusterIP"` |  |
| backend.service.http.targetPort | int | `8080` |  |
| backend.service.http.nodePort | string | `""` |  |
| backend.service.extraServices[0].name | string | `"jmx"` |  |
| backend.service.extraServices[0].port | int | `1099` |  |
| backend.service.extraServices[0].targetPort | int | `1099` |  |
| backend.service.extraOptions | object | `{}` |  |
| backend.initContainers | list | `[]` |  |
| backend.command | list | `[]` |  |
| backend.args | list | `[]` |  |
| backend.podLabels | object | `{}` |  |
| backend.podAnnotations | object | `{}` |  |
| backend.extraOptionsSpec | object | `{}` |  |
| backend.extraOptionsTemplateSpec | object | `{}` |  |
| backend.extraEnvVars | list | `[]` |  |
| backend.extraEnvVarsCM | string | `""` |  |
| backend.extraEnvVarsSecret | string | `""` |  |
| backend.extraVolumes | list | `[]` |  |
| backend.extraVolumeMounts | list | `[]` |  |
| backend.podSecurityContext.enabled | bool | `true` |  |
| backend.podSecurityContext.fsGroup | int | `101` |  |
| backend.containerSecurityContext.enabled | bool | `true` |  |
| backend.containerSecurityContext.runAsUser | int | `101` |  |
| backend.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| backend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| backend.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| backend.resources | object | `{}` |  |
| backend.startupProbe.enabled | bool | `false` |  |
| backend.readinessProbe.enabled | bool | `true` |  |
| backend.readinessProbe.initialDelaySeconds | int | `5` |  |
| backend.readinessProbe.periodSeconds | int | `5` |  |
| backend.readinessProbe.timeoutSeconds | int | `3` |  |
| backend.readinessProbe.failureThreshold | int | `5` |  |
| backend.readinessProbe.successThreshold | int | `1` |  |
| backend.livenessProbe.enabled | bool | `true` |  |
| backend.livenessProbe.initialDelaySeconds | int | `5` |  |
| backend.livenessProbe.periodSeconds | int | `10` |  |
| backend.livenessProbe.timeoutSeconds | int | `3` |  |
| backend.livenessProbe.failureThreshold | int | `10` |  |
| backend.livenessProbe.successThreshold | int | `1` |  |
| frontend.image.registry | string | `"cr.seqera.io"` |  |
| frontend.image.repository | string | `"private/nf-tower-enterprise/frontend"` |  |
| frontend.image.tag | string | `""` |  |
| frontend.image.digest | string | `""` |  |
| frontend.image.pullPolicy | string | `"IfNotPresent"` |  |
| frontend.image.pullSecrets | list | `[]` |  |
| frontend.service.type | string | `"ClusterIP"` |  |
| frontend.service.http.port | int | `80` |  |
| frontend.service.http.targetPort | int | `8083` |  |
| frontend.service.extraServices | list | `[]` |  |
| frontend.service.extraOptions | object | `{}` |  |
| frontend.command | list | `[]` |  |
| frontend.args | list | `[]` |  |
| frontend.podLabels | object | `{}` |  |
| frontend.podAnnotations | object | `{}` |  |
| frontend.extraEnvVars | list | `[]` |  |
| frontend.extraEnvVarsCM | string | `""` |  |
| frontend.extraEnvVarsSecret | string | `""` |  |
| frontend.extraVolumes | list | `[]` |  |
| frontend.extraVolumeMounts | list | `[]` |  |
| frontend.podSecurityContext.enabled | bool | `true` |  |
| frontend.podSecurityContext.fsGroup | int | `101` |  |
| frontend.containerSecurityContext.enabled | bool | `true` |  |
| frontend.containerSecurityContext.runAsUser | int | `101` |  |
| frontend.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| frontend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| frontend.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| frontend.initContainers | list | `[]` |  |
| frontend.extraOptionsSpec | object | `{}` |  |
| frontend.extraOptionsTemplateSpec | object | `{}` |  |
| frontend.resources | object | `{}` |  |
| frontend.startupProbe.enabled | bool | `false` |  |
| frontend.livenessProbe.enabled | bool | `false` |  |
| frontend.readinessProbe.enabled | bool | `false` |  |
| cron.image.registry | string | `"cr.seqera.io"` |  |
| cron.image.repository | string | `"private/nf-tower-enterprise/backend"` |  |
| cron.image.tag | string | `""` |  |
| cron.image.digest | string | `""` |  |
| cron.image.pullPolicy | string | `"IfNotPresent"` |  |
| cron.image.pullSecrets | list | `[]` |  |
| cron.micronautEnvironments[0] | string | `"prod"` |  |
| cron.micronautEnvironments[1] | string | `"redis"` |  |
| cron.micronautEnvironments[2] | string | `"cron"` |  |
| cron.service.type | string | `"ClusterIP"` |  |
| cron.service.http.port | int | `8080` |  |
| cron.service.http.targetPort | int | `8082` |  |
| cron.service.extraServices | list | `[]` |  |
| cron.service.extraOptions | object | `{}` |  |
| cron.command | list | `[]` |  |
| cron.args | list | `[]` |  |
| cron.podLabels | object | `{}` |  |
| cron.podAnnotations | object | `{}` |  |
| cron.initContainers | list | `[]` |  |
| cron.extraOptionsSpec | object | `{}` |  |
| cron.extraOptionsTemplateSpec | object | `{}` |  |
| cron.extraEnvVars | list | `[]` |  |
| cron.extraEnvVarsCM | string | `""` |  |
| cron.extraEnvVarsSecret | string | `""` |  |
| cron.extraVolumes | list | `[]` |  |
| cron.extraVolumeMounts | list | `[]` |  |
| cron.podSecurityContext.enabled | bool | `true` |  |
| cron.podSecurityContext.fsGroup | int | `101` |  |
| cron.containerSecurityContext.enabled | bool | `true` |  |
| cron.containerSecurityContext.runAsUser | int | `101` |  |
| cron.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| cron.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| cron.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| cron.resources | object | `{}` |  |
| cron.startupProbe.enabled | bool | `false` |  |
| cron.readinessProbe.enabled | bool | `true` |  |
| cron.readinessProbe.initialDelaySeconds | int | `5` |  |
| cron.readinessProbe.timeoutSeconds | int | `3` |  |
| cron.livenessProbe.enabled | bool | `true` |  |
| cron.livenessProbe.initialDelaySeconds | int | `5` |  |
| cron.livenessProbe.timeoutSeconds | int | `3` |  |
| cron.livenessProbe.failureThreshold | int | `10` |  |
| cron.dbMigrationInitContainer.image.registry | string | `"cr.seqera.io"` |  |
| cron.dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/migrate-db"` |  |
| cron.dbMigrationInitContainer.image.tag | string | `""` |  |
| cron.dbMigrationInitContainer.image.digest | string | `""` |  |
| cron.dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| cron.dbMigrationInitContainer.image.pullSecrets | list | `[]` |  |
| cron.dbMigrationInitContainer.extraEnvVars | list | `[]` |  |
| cron.dbMigrationInitContainer.extraEnvVarsCM | string | `""` |  |
| cron.dbMigrationInitContainer.extraEnvVarsSecret | string | `""` |  |
| cron.dbMigrationInitContainer.extraVolumeMounts | list | `[]` |  |
| cron.dbMigrationInitContainer.resources | object | `{}` |  |
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
| serviceAccount.name | string | `""` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.imagePullSecretNames | list | `[]` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| ingress.enabled | bool | `false` |  |
| ingress.exposeApiDomain | bool | `false` |  |
| ingress.enableHostOnWWWSubdomain | bool | `true` |  |
| ingress.defaultBackend | object | `{}` |  |
| ingress.extraHosts | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.extraLabels | object | `{}` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.tls | list | `[]` |  |
| ingress.pathType | string | `"ImplementationSpecific"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
