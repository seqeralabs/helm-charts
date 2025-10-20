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
| backend.args | list | `[]` |  |
| backend.command | list | `[]` |  |
| backend.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| backend.containerSecurityContext.enabled | bool | `true` |  |
| backend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| backend.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| backend.containerSecurityContext.runAsUser | int | `101` |  |
| backend.extraEnvVars | list | `[]` |  |
| backend.extraEnvVarsCM | string | `""` |  |
| backend.extraEnvVarsSecret | string | `""` |  |
| backend.extraOptionsSpec | object | `{}` |  |
| backend.extraOptionsTemplateSpec | object | `{}` |  |
| backend.extraVolumeMounts | list | `[]` |  |
| backend.extraVolumes | list | `[]` |  |
| backend.image.digest | string | `""` |  |
| backend.image.pullPolicy | string | `"IfNotPresent"` |  |
| backend.image.pullSecrets | list | `[]` |  |
| backend.image.registry | string | `"cr.seqera.io"` |  |
| backend.image.repository | string | `"private/nf-tower-enterprise/backend"` |  |
| backend.image.tag | string | `""` |  |
| backend.initContainers | list | `[]` |  |
| backend.livenessProbe.enabled | bool | `true` |  |
| backend.livenessProbe.failureThreshold | int | `10` |  |
| backend.livenessProbe.initialDelaySeconds | int | `5` |  |
| backend.livenessProbe.periodSeconds | int | `10` |  |
| backend.livenessProbe.successThreshold | int | `1` |  |
| backend.livenessProbe.timeoutSeconds | int | `3` |  |
| backend.micronautEnvironments[0] | string | `"prod"` |  |
| backend.micronautEnvironments[1] | string | `"redis"` |  |
| backend.micronautEnvironments[2] | string | `"ha"` |  |
| backend.podAnnotations | object | `{}` |  |
| backend.podLabels | object | `{}` |  |
| backend.podSecurityContext.enabled | bool | `true` |  |
| backend.podSecurityContext.fsGroup | int | `101` |  |
| backend.readinessProbe.enabled | bool | `true` |  |
| backend.readinessProbe.failureThreshold | int | `5` |  |
| backend.readinessProbe.initialDelaySeconds | int | `5` |  |
| backend.readinessProbe.periodSeconds | int | `5` |  |
| backend.readinessProbe.successThreshold | int | `1` |  |
| backend.readinessProbe.timeoutSeconds | int | `3` |  |
| backend.resources | object | `{}` |  |
| backend.service.extraOptions | object | `{}` |  |
| backend.service.extraServices[0].name | string | `"jmx"` |  |
| backend.service.extraServices[0].port | int | `1099` |  |
| backend.service.extraServices[0].targetPort | int | `1099` |  |
| backend.service.http.nodePort | string | `""` |  |
| backend.service.http.targetPort | int | `8080` |  |
| backend.service.type | string | `"ClusterIP"` |  |
| backend.startupProbe.enabled | bool | `false` |  |
| commonAnnotations | object | `{}` |  |
| commonLabels | object | `{}` |  |
| cron.args | list | `[]` |  |
| cron.command | list | `[]` |  |
| cron.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| cron.containerSecurityContext.enabled | bool | `true` |  |
| cron.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| cron.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| cron.containerSecurityContext.runAsUser | int | `101` |  |
| cron.dbMigrationInitContainer.extraEnvVars | list | `[]` |  |
| cron.dbMigrationInitContainer.extraEnvVarsCM | string | `""` |  |
| cron.dbMigrationInitContainer.extraEnvVarsSecret | string | `""` |  |
| cron.dbMigrationInitContainer.extraVolumeMounts | list | `[]` |  |
| cron.dbMigrationInitContainer.image.digest | string | `""` |  |
| cron.dbMigrationInitContainer.image.pullPolicy | string | `"IfNotPresent"` |  |
| cron.dbMigrationInitContainer.image.pullSecrets | list | `[]` |  |
| cron.dbMigrationInitContainer.image.registry | string | `"cr.seqera.io"` |  |
| cron.dbMigrationInitContainer.image.repository | string | `"private/nf-tower-enterprise/migrate-db"` |  |
| cron.dbMigrationInitContainer.image.tag | string | `""` |  |
| cron.dbMigrationInitContainer.resources | object | `{}` |  |
| cron.extraEnvVars | list | `[]` |  |
| cron.extraEnvVarsCM | string | `""` |  |
| cron.extraEnvVarsSecret | string | `""` |  |
| cron.extraOptionsSpec | object | `{}` |  |
| cron.extraOptionsTemplateSpec | object | `{}` |  |
| cron.extraVolumeMounts | list | `[]` |  |
| cron.extraVolumes | list | `[]` |  |
| cron.image.digest | string | `""` |  |
| cron.image.pullPolicy | string | `"IfNotPresent"` |  |
| cron.image.pullSecrets | list | `[]` |  |
| cron.image.registry | string | `"cr.seqera.io"` |  |
| cron.image.repository | string | `"private/nf-tower-enterprise/backend"` |  |
| cron.image.tag | string | `""` |  |
| cron.initContainers | list | `[]` |  |
| cron.livenessProbe.enabled | bool | `true` |  |
| cron.livenessProbe.failureThreshold | int | `10` |  |
| cron.livenessProbe.initialDelaySeconds | int | `5` |  |
| cron.livenessProbe.timeoutSeconds | int | `3` |  |
| cron.micronautEnvironments[0] | string | `"prod"` |  |
| cron.micronautEnvironments[1] | string | `"redis"` |  |
| cron.micronautEnvironments[2] | string | `"cron"` |  |
| cron.podAnnotations | object | `{}` |  |
| cron.podLabels | object | `{}` |  |
| cron.podSecurityContext.enabled | bool | `true` |  |
| cron.podSecurityContext.fsGroup | int | `101` |  |
| cron.readinessProbe.enabled | bool | `true` |  |
| cron.readinessProbe.initialDelaySeconds | int | `5` |  |
| cron.readinessProbe.timeoutSeconds | int | `3` |  |
| cron.resources | object | `{}` |  |
| cron.service.extraOptions | object | `{}` |  |
| cron.service.extraServices | list | `[]` |  |
| cron.service.http.port | int | `8080` |  |
| cron.service.http.targetPort | int | `8082` |  |
| cron.service.type | string | `"ClusterIP"` |  |
| cron.startupProbe.enabled | bool | `false` |  |
| extraDeploy | list | `[]` |  |
| frontend.args | list | `[]` |  |
| frontend.command | list | `[]` |  |
| frontend.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| frontend.containerSecurityContext.enabled | bool | `true` |  |
| frontend.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| frontend.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| frontend.containerSecurityContext.runAsUser | int | `101` |  |
| frontend.extraEnvVars | list | `[]` |  |
| frontend.extraEnvVarsCM | string | `""` |  |
| frontend.extraEnvVarsSecret | string | `""` |  |
| frontend.extraOptionsSpec | object | `{}` |  |
| frontend.extraOptionsTemplateSpec | object | `{}` |  |
| frontend.extraVolumeMounts | list | `[]` |  |
| frontend.extraVolumes | list | `[]` |  |
| frontend.image.digest | string | `""` |  |
| frontend.image.pullPolicy | string | `"IfNotPresent"` |  |
| frontend.image.pullSecrets | list | `[]` |  |
| frontend.image.registry | string | `"cr.seqera.io"` |  |
| frontend.image.repository | string | `"private/nf-tower-enterprise/frontend"` |  |
| frontend.image.tag | string | `""` |  |
| frontend.initContainers | list | `[]` |  |
| frontend.livenessProbe.enabled | bool | `false` |  |
| frontend.podAnnotations | object | `{}` |  |
| frontend.podLabels | object | `{}` |  |
| frontend.podSecurityContext.enabled | bool | `true` |  |
| frontend.podSecurityContext.fsGroup | int | `101` |  |
| frontend.readinessProbe.enabled | bool | `false` |  |
| frontend.resources | object | `{}` |  |
| frontend.service.extraOptions | object | `{}` |  |
| frontend.service.extraServices | list | `[]` |  |
| frontend.service.http.port | int | `80` |  |
| frontend.service.http.targetPort | int | `8083` |  |
| frontend.service.type | string | `"ClusterIP"` |  |
| frontend.startupProbe.enabled | bool | `false` |  |
| global.apiDomain | string | `"{{ printf \"api.%s\" .Values.global.platformExternalDomain }}"` |  |
| global.contentDomain | string | `"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"` |  |
| global.contentUrl | string | `"{{ printf \"https://%s\" (tpl .Values.global.contentDomain $) }}"` |  |
| global.imageCredentials | list | `[]` |  |
| global.platformDatabase.database | string | `""` |  |
| global.platformDatabase.existingSecretKey | string | `""` |  |
| global.platformDatabase.existingSecretName | string | `""` |  |
| global.platformDatabase.host | string | `""` |  |
| global.platformDatabase.password | string | `""` |  |
| global.platformDatabase.port | int | `3306` |  |
| global.platformDatabase.username | string | `""` |  |
| global.platformExternalDomain | string | `"example.com"` |  |
| global.platformServiceAddress | string | `"{{ printf \"%s-backend\" (include \"common.names.fullname\" .) }}"` |  |
| global.platformServicePort | int | `8080` |  |
| global.platformUrl | string | `"{{ printf \"https://%s\" (tpl .Values.global.platformExternalDomain $) }}"` |  |
| global.redis.auth.enabled | bool | `false` |  |
| global.redis.auth.existingSecretKey | string | `""` |  |
| global.redis.auth.existingSecretName | string | `""` |  |
| global.redis.auth.password | string | `""` |  |
| global.redis.host | string | `""` |  |
| global.redis.port | int | `6379` |  |
| global.redis.tls.enabled | bool | `false` |  |
| ingress.annotations | object | `{}` |  |
| ingress.defaultBackend | object | `{}` |  |
| ingress.enableHostOnWWWSubdomain | bool | `true` |  |
| ingress.enabled | bool | `false` |  |
| ingress.exposeApiDomain | bool | `false` |  |
| ingress.extraHosts | list | `[]` |  |
| ingress.extraLabels | object | `{}` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| initContainersUtils.waitForCronImage.digest | string | `""` |  |
| initContainersUtils.waitForCronImage.pullPolicy | string | `"IfNotPresent"` |  |
| initContainersUtils.waitForCronImage.registry | string | `""` |  |
| initContainersUtils.waitForCronImage.repository | string | `"curlimages/curl"` |  |
| initContainersUtils.waitForCronImage.tag | string | `"latest"` |  |
| initContainersUtils.waitForMySQLImage.digest | string | `""` |  |
| initContainersUtils.waitForMySQLImage.pullPolicy | string | `"IfNotPresent"` |  |
| initContainersUtils.waitForMySQLImage.registry | string | `""` |  |
| initContainersUtils.waitForMySQLImage.repository | string | `"mysql"` |  |
| initContainersUtils.waitForMySQLImage.tag | string | `"9"` |  |
| initContainersUtils.waitForRedisImage.digest | string | `""` |  |
| initContainersUtils.waitForRedisImage.pullPolicy | string | `"IfNotPresent"` |  |
| initContainersUtils.waitForRedisImage.registry | string | `""` |  |
| initContainersUtils.waitForRedisImage.repository | string | `"redis"` |  |
| initContainersUtils.waitForRedisImage.tag | string | `"7"` |  |
| redis.auth.enabled | bool | `false` |  |
| redis.auth.existingSecretKey | string | `""` |  |
| redis.auth.existingSecretName | string | `""` |  |
| redis.auth.password | string | `""` |  |
| redis.host | string | `""` |  |
| redis.port | int | `6379` |  |
| redis.prefix | string | `""` |  |
| redis.tls.enabled | bool | `false` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| serviceAccount.imagePullSecretNames | list | `[]` |  |
| serviceAccount.name | string | `""` |  |
| tower.YAMLConfigFileContent | string | `""` |  |
| tower.awsSesEnable | bool | `false` |  |
| tower.configMapAnnotations | object | `{}` |  |
| tower.configMapLabels | object | `{}` |  |
| tower.contactEmail | string | `"tower-support@example.com"` |  |
| tower.cryptoSeedSecretKey | string | `""` |  |
| tower.cryptoSeedSecretName | string | `""` |  |
| tower.cryptoSeedString | string | `""` |  |
| tower.db.dialect | string | `"io.seqera.util.MySQL55DialectCollateBin"` |  |
| tower.db.driver | string | `"org.mariadb.jdbc.Driver"` |  |
| tower.db.maxLifetime | string | `"60000"` |  |
| tower.db.maxPoolSize | string | `"5"` |  |
| tower.db.minPoolSize | string | `"0"` |  |
| tower.enablePlatforms | string | `"altair-platform,awsbatch-platform,azbatch-platform,eks-platform,googlebatch-platform,gke-platform,k8s-platform,lsf-platform,moab-platform,slurm-platform"` |  |
| tower.flywayLocations | string | `"classpath:db-schema/mysql"` |  |
| tower.jwtSeedSecretKey | string | `""` |  |
| tower.jwtSeedSecretName | string | `""` |  |
| tower.jwtSeedString | string | `""` |  |
| tower.licenseSecretKey | string | `""` |  |
| tower.licenseSecretName | string | `""` |  |
| tower.licenseString | string | `""` |  |
| tower.secretAnnotations | object | `{}` |  |
| tower.secretLabels | object | `{}` |  |
| tower.serviceAnnotations | object | `{}` |  |
| tower.serviceLabels | object | `{}` |  |
| tower.smtp.existingSecretKey | string | `""` |  |
| tower.smtp.existingSecretName | string | `""` |  |
| tower.smtp.host | string | `""` |  |
| tower.smtp.password | string | `""` |  |
| tower.smtp.port | string | `""` |  |
| tower.smtp.user | string | `""` |  |
| tower.waveServerUrl | string | `"https://wave.seqera.io"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
