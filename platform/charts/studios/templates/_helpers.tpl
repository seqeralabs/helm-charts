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

{{/* Let the user specify a ServiceAccount name, or default to the same Service Account name used
by the Seqera Platform Terraform module.
*/}}
{{- define "studios.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end -}}

{{/* Return the hostname of the redis server.
Chart-specific values take precedence over global values. */}}
{{- define "studios.redis.host" -}}
  {{- if .Values.redis.host }}
  {{- .Values.redis.host }}
  {{- end -}}
{{- end -}}

{{/* Return the port of the redis server.
Chart-specific values take precedence over global values. */}}
{{- define "studios.redis.port" -}}
  {{- if .Values.redis.port }}
  {{- .Values.redis.port }}
  {{- end -}}
{{- end -}}

{{/* Return whether TLS is enabled for the redis server.
Chart-specific values take precedence over global values. */}}
{{- define "studios.redis.tlsEnabled" -}}
  {{- if or .Values.redis.enableTls -}}
true
  {{- else -}}
false
  {{- end -}}
{{- end -}}

{{/* Return the redis prefix to use for Studios data. */}}
{{- define "studios.redis.prefix" -}}
  {{- if .Values.redis.prefix }}
  {{- tpl .Values.redis.prefix $ }}
  {{- end -}}
{{- end -}}

{{- define "studios.redis.isAuthEnabled" -}}
  {{- if or (tpl .Values.redis.password $) (include "studios.redis.existingSecret" $) -}}
true
  {{- end -}}
{{- end -}}

{{/* Redis authentication helpers */}}
{{- define "studios.redis.existingSecret" -}}
  {{- printf "%s" (tpl .Values.redis.existingSecretName $) -}}
{{- end -}}
{{- define "studios.redis.secretName" -}}
  {{- include "studios.redis.existingSecret" $ | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "studios.redis.secretKey" -}}
  {{- printf "%s" (tpl .Values.redis.existingSecretKey $) | default "CONNECT_REDIS_PASSWORD" -}}
{{- end -}}

{{/* OIDC client registration token secret helpers

Example usage from within studios chart:
name: {{ include "studios.oidcToken.secretName" . }}
key: {{ include "studios.oidcToken.secretKey" . }}

Example usage from parent platform chart:
{{- $studiosContext := dict "Chart" (dict "Name" "studios") "Release" .Release "Values" .Values.studios -}}
name: {{ include "studios.oidcToken.secretName" $studiosContext }}
key: {{ include "studios.oidcToken.secretKey" $studiosContext }}
*/}}
{{- define "studios.oidcToken.existingSecret" -}}
  {{- printf "%s" (tpl .Values.proxy.oidcClientRegistrationTokenSecretName .) -}}
{{- end -}}
{{- define "studios.oidcToken.secretName" -}}
  {{- include "studios.oidcToken.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "studios.oidcToken.secretKey" -}}
  {{- if (include "studios.oidcToken.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.proxy.oidcClientRegistrationTokenSecretKey .) | default "OIDC_CLIENT_REGISTRATION_TOKEN" -}}
  {{- else -}}
    {{- printf "OIDC_CLIENT_REGISTRATION_TOKEN" -}}
  {{- end -}}
{{- end -}}
