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
Create the name of the service account to use
*/}}
{{- define "wave.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end }}

{{/*
Return the name of the secret containing the database password.
*/}}
{{- define "wave.database.existingSecret" -}}
  {{- printf "%s" (tpl .Values.database.existingSecretName .) -}}
{{- end -}}
{{- define "wave.database.existingSecret.secretName" -}}
  {{- include "wave.database.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "wave.database.existingSecret.secretKey" -}}
  {{- if (include "wave.database.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.database.existingSecretKey .) | default "WAVE_DB_PASSWORD" -}}
  {{- else -}}
    {{- printf "WAVE_DB_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL URI.
*/}}
{{- define "wave.database.uri" -}}
  {{- printf "jdbc:postgresql://%s:%d/%s"
  (tpl .Values.database.host .)
  (.Values.database.port | int)
  (tpl .Values.database.name .)
  -}}
{{- end -}}

{{/*
Return the Redis URI for the wait-for-redis init container.
*/}}
{{- define "wave.redis.uri" -}}
  {{- printf "%s://%s:%d"
  (ternary "rediss" "redis" (.Values.redis.enableTls | toString | eq "true"))
  (tpl .Values.redis.host .)
  (.Values.redis.port | int)
  -}}
{{- end -}}

{{/*
Return the name of the secret containing the Redis password.
*/}}
{{- define "wave.redis.existingSecret" -}}
  {{- printf "%s" (tpl .Values.redis.existingSecretName .) -}}
{{- end -}}
{{- define "wave.redis.existingSecret.secretName" -}}
  {{- include "wave.redis.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{/*
Build the Wave micronaut envs list: always ensure required environments are present.
*/}}
{{- define "wave.micronautEnvs" -}}
  {{- $list := .Values.micronautEnvironments -}}
  {{/* Always make sure the required micronaut environments are added to the list */}}
  {{- $list = append $list "postgres" -}}
  {{- $list = append $list "redis" -}}
  {{- uniq $list | join "," | quote -}}
{{- end -}}

{{- define "wave.redis.existingSecret.secretKey" -}}
  {{- if (include "wave.redis.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.redis.existingSecretKey .) | default "WAVE_REDIS_PASSWORD" -}}
  {{- else -}}
    {{- printf "WAVE_REDIS_PASSWORD" -}}
  {{- end -}}
{{- end -}}
