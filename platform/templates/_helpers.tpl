{{/*
 Copyright (c) 2025 - 2026 Seqera Labs
 All rights reserved.

 SPDX-License-Identifier: Apache-2.0

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/}}

{{/*
Let the user specify a ServiceAccount name, or default to the same Service Account name used
by the Platform Terraform provider.
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
Return the backend service target port.
Only available in Platform v25.3+, in previous versions it was hardcoded to 8080.
*/}}
{{- define "platform.backend.targetPort" -}}
  {{- if semverCompare ">=25.3.0" $.Chart.AppVersion -}}
{{ tpl (toString .Values.backend.service.http.targetPort) . }}
  {{- else -}}
    {{- if ne (toString .Values.backend.service.http.targetPort) "8080" -}}
      {{- fail "backend.service.http.targetPort can only be customized in Platform v25.3.0+. Current version does not support custom target ports (must be 8080)." -}}
    {{- end -}}
8080
  {{- end -}}
{{- end -}}

{{/*
Filter backend probe port based on chart version.
Only available in Platform v25.3+, in previous versions it was hardcoded to 8080.
This helper takes the probe configuration, renders any templates, and returns a modified version with the correct port.
Handles both httpGet and tcpSocket probe types (exec probes don't use ports).

{{ include "platform.backend.filterProbe" (dict "probe" .Values.backend.livenessProbe "context" $) }}
*/}}
{{- define "platform.backend.filterProbe" -}}
  {{- $probe := .probe -}}
  {{- $context := .context -}}
  {{- $probeToRender := $probe -}}
  {{- if and (semverCompare "<25.3.0" $context.Chart.AppVersion) (or $probe.httpGet $probe.tcpSocket) -}}
    {{- /* For versions before 25.3.0, override the port to 8080 for httpGet or tcpSocket */ -}}
    {{- $probeToRender = merge (dict) $probe -}}
    {{- if $probe.httpGet -}}
      {{- $_ := set $probeToRender "httpGet" (merge (dict "port" 8080) $probe.httpGet) -}}
    {{- end -}}
    {{- if $probe.tcpSocket -}}
      {{- $_ := set $probeToRender "tcpSocket" (merge (dict "port" 8080) $probe.tcpSocket) -}}
    {{- end -}}
  {{- end -}}
  {{- include "seqera.tplvalues.render" (dict "value" $probeToRender "context" $context) -}}
{{- end -}}

{{/*
Build the backend micronaut envs list: add envs if features are requested in other values.
*/}}
{{- define "platform.backend.micronautEnvs" -}}
  {{- $list := .Values.backend.micronautEnvironments -}}
{{/* Always make sure the required micronaut environments are added to the list for backend */}}
{{- $list = append $list "prod" -}}
{{- $list = append $list "redis" -}}
{{- $list = append $list "ha" -}}
  {{/* Add wave to the list of microenvs if waveServerUrl is defined. */}}
  {{- if not (empty .Values.platform.waveServerUrl) -}}
{{- $list = append $list "wave" -}}
  {{- end -}}
  {{- /* Add groundswell to the list of microenvs if pipeline-optimization is enabled. */}}
  {{- if (index .Values "pipeline-optimization" "enabled") -}}
{{- $list = append $list "groundswell" -}}
  {{- end -}}
{{- uniq $list | join "," | quote -}}
{{- end -}}

{{/*
Build the cron micronaut envs list: add envs if features are requested in other values. */}}
{{- define "platform.cron.micronautEnvs" -}}
  {{- $list := .Values.cron.micronautEnvironments -}}
{{/* Always make sure the required micronaut environments are added to the list for cron */}}
{{- $list = append $list "prod" -}}
{{- $list = append $list "redis" -}}
{{- $list = append $list "cron" -}}
{{- uniq $list | join "," | quote -}}
{{- end -}}

{{/*
Return the name of the secret containing the Platform database password.
*/}}
{{- define "platform.database.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platformDatabase.existingSecretName $) -}}
{{- end -}}
{{- define "platform.database.secretName" -}}
  {{- include "platform.database.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}

{{- define "platform.database.secretKey" -}}
  {{- if (include "platform.database.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platformDatabase.existingSecretKey $) | default "TOWER_DB_PASSWORD" -}}
  {{- else -}}
    {{- printf "TOWER_DB_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the JDBC URL for the database connection, including connection options.
Constructs URL in format: jdbc:mysql://host:port/database?option1=value1&option2=value2

For now this template is built around the only driver that can be set, 'mariadb'.
*/}}
{{- define "platform.database.url" -}}
  {{- $baseUrl := printf "jdbc:mysql://%s:%d/%s"
  .Values.platformDatabase.host
  (.Values.platformDatabase.port | int)
  .Values.platformDatabase.name -}}
  {{- $options := list -}}
  {{/* Evaluate mysql first, so if both are defined we pick mariadb options. */}}
  {{- if .Values.platformDatabase.connectionOptions.mysql -}}
    {{- $options = .Values.platformDatabase.connectionOptions.mysql -}}
  {{- end -}}
  {{- if .Values.platformDatabase.connectionOptions.mariadb -}}
    {{- $options = .Values.platformDatabase.connectionOptions.mariadb -}}
  {{- end -}}

  {{- if $options -}}
    {{- printf "%s?%s" $baseUrl (join "&" $options) -}}
  {{- else -}}
    {{- $baseUrl -}}
  {{- end -}}
{{- end -}}

{{/*
Return the JDBC driver class name based on the selected database driver.
*/}}
{{- define "platform.database.driver" -}}
  {{- if or (eq .Values.platformDatabase.driver "mariadb") (eq .Values.platformDatabase.driver "mysql") -}}
org.mariadb.jdbc.Driver
  {{- else -}}
    {{- fail (printf "Unsupported database driver: '%s'. Supported drivers are: 'mariadb' (or its alias 'mysql')." .Values.platformDatabase.driver) -}}
  {{- end -}}
{{- end -}}

{{/*
Return the Hibernate dialect based on the selected database dialect.
*/}}
{{- define "platform.database.dialect" -}}
  {{- if eq .Values.platformDatabase.dialect "mysql-8" -}}
io.seqera.util.MySQL8DialectCollateBin
  {{- else if eq .Values.platformDatabase.dialect "mariadb-10" -}}
io.seqera.util.MariaDB10DialectCollateBin
  {{- else -}}
    {{- fail (printf "Unsupported database dialect: '%s'. Supported dialects are: 'mysql-8', 'mariadb-10'." .Values.platformDatabase.dialect) -}}
  {{- end -}}
{{- end -}}

{{/*
Return the hostname of the redis server.
Chart-specific values take precedence over global values.
*/}}
{{- define "platform.redis.host" -}}
  {{- /* Redis is a requirement checked in NOTES, so no need to check whether it was defined or not. */}}
  {{- printf "%s" (tpl .Values.redis.host $) -}}
{{- end -}}

{{/*
Return the port of the redis server.
Chart-specific values take precedence over global values.
*/}}
{{- define "platform.redis.port" -}}
  {{- printf "%s" (tpl (.Values.redis.port | toString) $) -}}
{{- end -}}

{{/*
Return whether TLS is enabled for the redis server.
Chart-specific values take precedence over global values.
*/}}
{{- define "platform.redis.tlsEnabled" -}}
  {{- if or .Values.redis.enableTls -}}
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
*/}}
{{- define "platform.redis.existingSecret" -}}
  {{- printf "%s" (tpl .Values.redis.existingSecretName $) -}}
{{- end -}}
{{- define "platform.redis.secretName" -}}
  {{- include "platform.redis.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{/*
Return the key of the secret containing the Redis password.
*/}}
{{- define "platform.redis.secretKey" -}}
  {{- if (include "platform.redis.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.redis.existingSecretKey $) | default "TOWER_REDIS_PASSWORD" -}}
  {{- else -}}
    {{- printf "TOWER_REDIS_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the JWT token.
*/}}
{{- define "platform.jwt.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platform.jwtSeedSecretName $) -}}
{{- end -}}
{{- define "platform.jwt.secretName" -}}
  {{- include "platform.jwt.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{- define "platform.jwt.secretKey" -}}
  {{- if (include "platform.jwt.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platform.jwtSeedSecretKey $) | default "TOWER_JWT_SECRET" -}}
  {{- else -}}
    {{- printf "TOWER_JWT_SECRET" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the crypto token.
*/}}
{{- define "platform.crypto.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platform.cryptoSeedSecretName $) -}}
{{- end -}}
{{- define "platform.crypto.secretName" -}}
  {{- include "platform.crypto.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{- define "platform.crypto.secretKey" -}}
  {{- if (include "platform.crypto.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platform.cryptoSeedSecretKey $) | default "TOWER_CRYPTO_SECRETKEY" -}}
  {{- else -}}
    {{- printf "TOWER_CRYPTO_SECRETKEY" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the Platform license token.
*/}}
{{- define "platform.license.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platform.licenseSecretName $) -}}
{{- end -}}
{{- define "platform.license.secretName" -}}
  {{- include "platform.license.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{- define "platform.license.secretKey" -}}
  {{- if (include "platform.license.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platform.licenseSecretKey $) | default "TOWER_LICENSE" -}}
  {{- else -}}
    {{- printf "TOWER_LICENSE" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the SMTP password.
*/}}
{{- define "platform.smtp.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platform.smtp.existingSecretName $) -}}
{{- end -}}
{{- define "platform.smtp.secretName" -}}
  {{- include "platform.smtp.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{- define "platform.smtp.secretKey" -}}
  {{- if (include "platform.smtp.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platform.smtp.existingSecretKey $) | default "TOWER_SMTP_PASSWORD" -}}
  {{- else -}}
    {{- printf "TOWER_SMTP_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the OIDC private key.
*/}}
{{- define "platform.oidc.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platform.oidcPrivateKeySecretName $) -}}
{{- end -}}
{{- define "studios.oidcPrivateKeySecretName" -}}
  {{- include "platform.oidc.existingSecret" $ | default (printf "%s-backend" (include "common.names.fullname" .)) -}}
{{- end -}}
{{- define "platform.oidc.secretKey" -}}
  {{- if (include "platform.oidc.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platform.oidcPrivateKeySecretKey $) | default "oidc.pem" -}}
  {{- else -}}
    {{- printf "oidc.pem" -}}
  {{- end -}}
{{- end -}}

{{/* Common initContainer to wait for Cron service to be ready.

{{ include "platform.initContainerWaitForCron" $ }}
*/}}
{{- define "platform.initContainerWaitForCron" -}}
  {{- with .Values.initContainerDependencies.waitForCron -}}
- name: wait-for-cron
  image: {{ include "common.images.image" (dict "imageRoot" .image "global" $.Values.global) }}
  imagePullPolicy: {{ .image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check for cron to be ready at \"${CRON_HOST}:${CRON_PORT}/health\""
      until curl -s ${CRON_HOST}:${CRON_PORT}/health |grep -q \"UP\"; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): cron ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: CRON_HOST
      value: {{ printf "%s-cron" (include "common.names.fullname" $) | quote }}
    - name: CRON_PORT
      value: {{ $.Values.cron.service.http.port | int | quote }}

  securityContext: {{- include "seqera.tplvalues.render" (dict "value" .securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" .resources) | nindent 4 }}
  {{- end -}}
{{- end -}}

{{/*
Validate a string value against DNS label naming conventions.

A DNS label must:
- contain at most 63 characters
- contain only lowercase alphanumeric characters or '-'
- start with an alphabetic character
- end with an alphanumeric character

Ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/

{{ include "platform.validate.dnsLabel" (dict "value" "value_to_validate") -}}
*/}}
{{- define "platform.validate.dnsLabel" -}}
  {{- $errors := list -}}
  {{- if gt (len .value) 63 -}}
{{- $errors = append $errors (printf "must not be longer than 63 characters") -}}
  {{- end -}}
  {{- if not (regexMatch "^[a-z]([-a-z0-9]*[a-z0-9])?$" .value) -}}
{{- $errors = append $errors (printf "'global.platformServiceAddress' must be a valid DNS subdomain (a-z, 0-9, and '-').") -}}
  {{- end -}}
  {{- if $errors -}}
{{- join "; " $errors -}}
  {{- end -}}
{{- end -}}

{{/*
Validate that a value is a string representation of an integer.

{{ include "platform.validate.isInteger" (dict "value" "value_to_validate") -}}
*/}}
{{- define "platform.validate.isInteger" -}}
  {{- $errors := list -}}
  {{- if not (regexMatch "^[0-9]+$" (.value | toString)) -}}
{{- $errors = append $errors (printf "must be an integer between 1 and 65535") -}}
  {{- end -}}
  {{- if .value | int |lt 65535 -}}
{{- $errors = append $errors (printf "must not be greater than 65535") -}}
  {{- end -}}
  {{- if $errors -}}
{{- join "; " $errors -}}
  {{- end -}}
{{- end -}}
