{{/* vim: set filetype=mustache: */}}

# The various URLs need to be set only if the related Domain wasn't unset.
# A user may not want to expose the content domain/url at all, and may disable it by setting an
# empty Domain variable, so we return nothing if the Domain variable was emptied.
{{- define "tower.contentUrl" -}}
{{- if and .Values.contentDomain (tpl .Values.contentDomain $) -}}
{{ tpl .Values.tower.contentUrl $ }}
{{- end -}}
{{- end -}}

{{/*
Let the user specify a ServiceAccount name, or default to the same Service Account name used
     by the Tower Terraform module.
*/}}
{{- define "platform.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end -}}

{{/*
Return the proper frontend image name.
If image tag and digest are not defined, termination fallbacks to chart appVersion.

Clone of common.images.image, specific for Platform frontend image since we want to select the
{chart.AppVersion}-unprivileged image when no tag is provided, which is the image running without
root and providing some options to change listening backend endpoint.
TODO: check whether we can deprecate the root-ful image.

{{ include "platform.frontend.image" ( dict "imageRoot" .Values.path.to.the.image "global" .Values.global "chart" .Chart ) }}
*/}}
{{- define "platform.frontend.image" -}}
{{- $registryName := default .imageRoot.registry ((.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}

{{- if not .imageRoot.tag }}
  {{- if .chart }}
    {{- $termination = printf "%s-unprivileged" .chart.AppVersion | toString -}}
  {{- end -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

{{/*
Build the backend micronaut envs list: add envs if features are requested in other values.
*/}}
{{- define "platform.backend.micronautEnvs" -}}
{{- $list := .Values.backend.micronautEnvironments -}}
{{/*
always make sure redis is added to the list of microenvs */}}
{{- $list = append $list "redis" -}}
{{/*
Add wave to the list of microenvs if waveServerUrl is defined. */}}
{{- if not (empty .Values.tower.waveServerUrl) -}}
  {{- $list = append $list "wave" -}}
{{- end -}}
{{- uniq $list | join "," | quote -}}
{{- end -}}

{{/*
Build the cron micronaut envs list: add envs if features are requested in other values. */}}
{{- define "platform.cron.micronautEnvs" -}}
{{- $list := .Values.cron.micronautEnvironments -}}
{{/*
always make sure redis is added to the list of microenvs */}}
{{- $list = append $list "redis" -}}
{{- uniq $list | join "," | quote -}}
{{- end -}}

{{/*
Return the name of the secret containing the MySQL credentials. */}}
{{- define "platform.database.secretName" -}}
{{ tpl .Values.global.platformDatabase.existingSecret $ }}
{{- end -}}

{{/*
Return the hostname of the redis server.
Chart-specific values take precedence over global values.

TODO: use a helm variable := to store the tpl result to avoid multiple evaluations
*/}}
{{- define "platform.redis.host" -}}
{{- if (tpl .Values.redis.host $) }}
  {{- tpl .Values.redis.host $ }}
{{- else if (tpl .Values.global.redis.host $) }}
  {{- tpl .Values.global.redis.host $ }}
{{- end -}}
{{- end -}}

{{/*
Return the port of the redis server.
Chart-specific values take precedence over global values.
*/}}
{{- define "platform.redis.port" -}}
{{- if (tpl (.Values.redis.port | toString ) $) }}
  {{- tpl (.Values.redis.port | toString) $ }}
{{- else if (tpl (.Values.global.redis.port | toString) $) }}
  {{- tpl (.Values.global.redis.port | toString) $ }}
{{- end -}}
{{- end -}}

{{/*
Return whether TLS is enabled for the redis server.
Chart-specific values take precedence over global values.
*/}}
{{- define "platform.redis.tlsEnabled" -}}
{{- if or .Values.redis.tls.enabled .Values.global.redis.tls.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Return the Redis URI. */}}
{{- define "platform.redis.uri" -}}
{{- printf "%s://%s:%d"
            (ternary "rediss" "redis" (eq (include "platform.redis.tlsEnabled" .) "true"))
            (include "platform.redis.host" .)
            (include "platform.redis.port" . | int )
-}}
{{- end -}}

{{/*
Return the name of the secret containing the Redis password.
'redis.auth' takes precedence over 'global.redis.auth'.
*/}}
{{- define "platform.redis.secretName" -}}
{{- if and .Values.redis.auth.enabled .Values.redis.auth.existingSecretName -}}
  {{- tpl .Values.redis.auth.existingSecretName $ -}}
{{- else if and .Values.global.redis.auth.enabled .Values.global.redis.auth.existingSecretName -}}
  {{- tpl .Values.global.redis.auth.existingSecretName $ -}}
{{- end -}}
{{- end -}}

{{/*
Return the key of the secret containing the Redis password.
'redis.auth' takes precedence over 'global.redis.auth'.
*/}}
{{- define "platform.redis.secretKey" -}}
{{- if and .Values.redis.auth.enabled .Values.redis.auth.existingSecretName .Values.redis.auth.existingSecretKey -}}
  {{- printf "%s" (tpl .Values.redis.auth.existingSecretKey $) -}}
{{- else if and .Values.global.redis.auth.enabled .Values.global.redis.auth.existingSecretName .Values.global.redis.auth.existingSecretKey -}}
  {{- printf "%s" (tpl .Values.global.redis.auth.existingSecretKey $) -}}
{{- else -}}
  {{- printf "TOWER_REDIS_PASSWORD" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the JWT token.
*/}}
{{- define "platform.jwt.secretName" -}}
{{- if .Values.tower.jwtSeedSecretName -}}
  {{- tpl .Values.tower.jwtSeedSecretName $ -}}
{{- else -}}
  {{- /* When no external secret is passed, default to the secret name that will store the token.
       On the first execution, the lookup function will not find the secret and will generate a
       random token; on successive executions, the lookup function will find the secret and will
       extract and re-save the token back in its original key. */ -}}
  {{- printf "%s-backend" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "platform.jwt.secretKey" -}}
{{- if and .Values.tower.jwtSeedSecretName .Values.tower.jwtSeedSecretKey -}}
{{- printf "%s" (tpl .Values.tower.jwtSeedSecretKey $) -}}
{{- else -}}
{{- printf "TOWER_JWT_SECRET" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the crypto token.
*/}}
{{- define "platform.crypto.secretName" -}}
{{- if .Values.tower.cryptoSeedSecretName -}}
  {{- tpl .Values.tower.cryptoSeedSecretName $ -}}
{{- else -}}
  {{- printf "%s-backend" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "platform.crypto.secretKey" -}}
{{- if and .Values.tower.cryptoSeedSecretName .Values.tower.cryptoSeedSecretKey -}}
{{- printf "%s" (tpl .Values.tower.cryptoSeedSecretKey $) -}}
{{- else -}}
{{- printf "TOWER_CRYPTO_SECRETKEY" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the Platform license token.
*/}}
{{- define "platform.license.secretName" -}}
{{- if .Values.tower.licenseSecretName -}}
  {{- tpl .Values.tower.licenseSecretName $ -}}
{{- else -}}
  {{- printf "%s-backend" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "platform.license.secretKey" -}}
{{- if and .Values.tower.licenseSecretName .Values.tower.licenseSecretKey -}}
{{- printf "%s" (tpl .Values.tower.licenseSecretKey $) -}}
{{- else -}}
{{- printf "TOWER_LICENSE" -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the SMTP password.
*/}}
{{- define "platform.smtp.secretName" -}}
{{- if .Values.tower.smtp.existingSecretName -}}
  {{- tpl .Values.tower.smtp.existingSecretName $ -}}
{{- else -}}
  {{- printf "%s-backend" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "platform.smtp.secretKey" -}}
{{- if and .Values.tower.smtp.existingSecretName .Values.tower.smtp.existingSecretKey -}}
{{- printf "%s" (tpl .Values.tower.smtp.existingSecretKey $) -}}
{{- else -}}
{{- printf "TOWER_SMTP_PASSWORD" -}}
{{- end -}}
{{- end -}}

{{/*
Tower database password environment variable entry.
*/}}
{{- define "platform.database.envVarPassword" -}}
- name: TOWER_DB_PASSWORD
  {{ if (include "platform.database.secretName" .) }}
  valueFrom:
    secretKeyRef:
      name: {{ include "platform.database.secretName" . | quote }}
      key: mysql-password
  {{ else }}
  value: {{ .Values.global.platformDatabase.password | quote }}
  {{ end }}
{{- end -}}

{{/*
Tower JWT seed environment variable entry.

This will only add the env var if the user passed an external Secret, otherwise if the seed
was passed as string or let to Helm to create it, it's added in the main Tower backend Secret.
*/}}
{{- define "tower.jwt.envVarSeed" -}}
{{- if .Values.tower.jwtSeedSecretName }}
- name: TOWER_JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.tower.jwtSeedSecretName | quote }}
      key: TOWER_JWT_SECRET
{{- end -}}
{{- end -}}

{{/*
Tower crypto seed environment variable entry.

This will only add the env var if the user passed an external Secret, otherwise if the seed
was passed as string or let to Helm to create it, it's added in the main Tower backend Secret.
*/}}
{{- define "tower.crypto.envVarSeed" -}}
{{- if .Values.tower.cryptoSeedSecretName }}
- name: TOWER_CRYPTO_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.tower.cryptoSeedSecretName | quote }}
      key: TOWER_CRYPTO_SECRETKEY
{{- end -}}
{{- end -}}

{{- define "tower.containerSecurityContextMinimal" -}}
securityContext:
  runAsUser: 101
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
{{- end -}}

{{- define "tower.resourcesMinimal" -}}
resources:
  requests:
    cpu: "0.5"
    memory: "50Mi"
  limits:
    memory: "100Mi"
{{- end -}}

{{/*
Tower License environment variable entry.

This will only add the env var if the user passed an external Secret, otherwise if the seed
was passed as string it's added in the main Tower backend Secret.
A License can't be generated with a random value, it has to be provided by a Seqera Labs
account manager.
*/}}
{{- define "tower.license.envVar" -}}
{{- if .Values.tower.licenseSecretName }}
- name: TOWER_LICENSE
  valueFrom:
    secretKeyRef:
      name: {{ .Values.tower.licenseSecretName | quote }}
      key: TOWER_LICENSE
{{- end -}}
{{- end -}}

{{/*
Common initContainer to wait for MySQL database to be ready.

{{ include "tower.initContainerWaitForDB" (dict "deployment" .Values.cron "context" $) }}
*/}}
{{- define "tower.initContainerWaitForDB" -}}
- name: wait-for-db
  image: {{ include "common.images.image" (dict "imageRoot" .context.Values.initContainersUtils.waitForMySQLImage "global" .context.Values.global) }}
  imagePullPolicy: {{ .context.Values.initContainersUtils.waitForMySQLImage.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check for db $DB_HOST:$DB_PORT"
      until mysql -h "$DB_HOST" -P "$DB_PORT" -D "$DB_NAME" -u"$DB_USERNAME" -p"$TOWER_DB_PASSWORD" -e "SELECT VERSION()"; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): db server ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: DB_HOST
      value: {{ .context.Values.global.platformDatabase.host | quote }}
    - name: DB_PORT
      value: {{ .context.Values.global.platformDatabase.port | quote }}
    - name: DB_NAME
      value: {{ .context.Values.global.platformDatabase.name | quote }}
    - name: DB_USERNAME
      value: {{ .context.Values.global.platformDatabase.username | quote }}
    {{ include "platform.database.envVarPassword" .context | nindent 4 }}

  {{ include "tower.containerSecurityContextMinimal" . | nindent 2 }}
  {{ include "tower.resourcesMinimal" . | nindent 2 }}
{{- end -}}

{{/*
Common initContainer to wait for Redis to be ready.

{{ include "tower.initContainerWaitForRedis" (dict "deployment" .Values.cron "context" $) }}
*/}}
{{- define "tower.initContainerWaitForRedis" -}}
{{- if .context.Values.redis.enabled -}}
- name: wait-for-redis
  image: {{ include "common.images.image" (dict "imageRoot" .context.Values.initContainersUtils.waitForRedisImage "global" .context.Values.global) }}
  imagePullPolicy: {{ .context.Values.initContainersUtils.waitForRedisImage.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check redis host '$REDIS_URI' with password (if set) '$REDISCLI_AUTH'";
      until redis-cli -u "$REDIS_URI" get hello; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): redis server ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: REDIS_URI
      value: {{ include "platform.redis.uri" .context | quote }}
    {{- if .context.Values.redis.auth.enabled }}
    - name: REDISCLI_AUTH
      {{ if .context.Values.redis.auth.password }}
      value: {{ .context.Values.redis.auth.password | quote }}
      {{- else -}}
      valueFrom:
        secretKeyRef:
          name: {{ include "tower.redis.secretName" .context | quote }}
          key: redis-password
      {{- end }}
    {{- end }}

  {{ include "tower.containerSecurityContextMinimal" . | nindent 2 }}
  {{ include "tower.resourcesMinimal" . | nindent 2 }}
{{ end }}
{{- end -}}
