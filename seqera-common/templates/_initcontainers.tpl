{{/*
 Copyright (c) 2026 Seqera Labs
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
Common initContainer to wait for MySQL database to be ready.

Usage examples:
include "seqera.initContainers.waitForMySQL" (dict "name" "pipeline-optimization-db" "waitValues" .Values.initContainerDependencies.waitForMySQL "connDetails" .Values.database         "secretNameTemplate" "pipeline-optimization.database.secretName"         "secretKeyTemplate" "pipeline-optimization.database.secretKey"         "context" $)
include "seqera.initContainers.waitForMySQL" (dict "name" "platform-db"              "waitValues" .Values.initContainerDependencies.waitForMySQL "connDetails" .Values.platformDatabase "secretNameTemplate" "pipeline-optimization.platformDatabase.secretName" "secretKeyTemplate" "pipeline-optimization.platformDatabase.secretKey" "context" $)
*/}}
{{- define "seqera.initContainers.waitForMySQL" -}}
- name: wait-for-{{ .name }}
  image: {{ include "seqera.images.image" (dict "imageRoot" .waitValues.image "global" .context.Values.global "chart" .context.Chart "cloudProviderImageKey" .cloudProviderImageKey "context" .context) }}
  imagePullPolicy: {{ .waitValues.image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check for db $DB_HOST:$DB_PORT"
      until mysql -h "$DB_HOST" -P "$DB_PORT" -D "$DB_NAME" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT VERSION()"; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): db server ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: DB_HOST
      value: {{ .connDetails.host | quote }}
    - name: DB_PORT
      value: {{ .connDetails.port | quote }}
    - name: DB_NAME
      value: {{ .connDetails.name | quote }}
    - name: DB_USERNAME
      value: {{ .connDetails.username | quote }}
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include .secretNameTemplate .context }}
          key: {{ include .secretKeyTemplate .context }}
  securityContext: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.resources) | nindent 4 }}
{{- end -}}

{{/*
Common initContainer to wait for Redis to be ready.

Usage example:
include "seqera.initContainers.waitForRedis" (dict "name" "redis" "waitValues" .Values.initContainerDependencies.waitForRedis "uriTemplate" "platform.redis.uri" "secretNameTemplate" "platform.redis.secretName" "secretKeyTemplate" "platform.redis.secretKey" "context" $)
*/}}
{{- define "seqera.initContainers.waitForRedis" -}}
- name: wait-for-{{ .name }}
  image: {{ include "seqera.images.image" (dict "imageRoot" .waitValues.image "global" .context.Values.global "chart" .context.Chart "cloudProviderImageKey" .cloudProviderImageKey "context" .context) }}
  imagePullPolicy: {{ .waitValues.image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check redis '$REDIS_URI' with password (if set) '$REDISCLI_AUTH'";
      until redis-cli -u "$REDIS_URI" get hello; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): redis server ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: REDIS_URI
      value: {{ include .uriTemplate .context | quote }}
  {{- if or .context.Values.redis.password .context.Values.redis.existingSecretName }}
    - name: REDISCLI_AUTH
      valueFrom:
        secretKeyRef:
          name: {{ include .secretNameTemplate .context }}
          key: {{ include .secretKeyTemplate .context }}
  {{- end }}

  securityContext: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.resources) | nindent 4 }}
{{- end -}}

{{/*
Common initContainer to wait for Seqera Platform to be ready.

Usage example:
include "seqera.initContainers.waitForPlatform" (dict "name" "platform" "waitValues" .Values.initContainerDependencies.waitForPlatform "platformHost" .Values.global.platformServiceAddress "platformPort" .Values.global.platformServicePort "context" $)
*/}}
{{- define "seqera.initContainers.waitForPlatform" -}}
- name: wait-for-{{ .name }}
  image: {{ include "seqera.images.image" (dict "imageRoot" .waitValues.image "global" .context.Values.global "chart" .context.Chart "cloudProviderImageKey" .cloudProviderImageKey "context" .context) }}
  imagePullPolicy: {{ .waitValues.image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      echo "$(date): starting check for platform to be ready at \"${PLATFORM_HOST}:${PLATFORM_PORT}/health\""
      until curl -s ${PLATFORM_HOST}:${PLATFORM_PORT}/health |grep -q \"UP\"; do
        echo "$(date): see you in $SLEEP_PERIOD_SECONDS seconds"
        sleep $SLEEP_PERIOD_SECONDS
      done
      echo "$(date): platform ready"
  env:
    - name: SLEEP_PERIOD_SECONDS
      value: "5"
    - name: PLATFORM_HOST
      value: {{ tpl .platformHost .context | quote }}
    - name: PLATFORM_PORT
      value: {{ .platformPort | int | quote }}
  securityContext: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.resources) | nindent 4 }}
{{- end -}}
