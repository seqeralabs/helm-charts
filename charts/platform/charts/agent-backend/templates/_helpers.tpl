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
{{- define "agent-backend.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end }}

{{/*
Return the name of the secret containing the database password.
*/}}
{{- define "agent-backend.database.existingSecret" -}}
  {{- printf "%s" (tpl .Values.database.existingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.database.existingSecret.secretName" -}}
  {{- include "agent-backend.database.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.database.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.database.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.database.existingSecretKey .) | default "AGENT_BACKEND_DB_PASSWORD" -}}
  {{- else -}}
    {{- printf "AGENT_BACKEND_DB_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the Anthropic API key.
*/}}
{{- define "agent-backend.anthropic.existingSecret" -}}
  {{- printf "%s" (tpl .Values.anthropic.existingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.anthropic.existingSecret.secretName" -}}
  {{- include "agent-backend.anthropic.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.anthropic.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.anthropic.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.anthropic.existingSecretKey .) | default "ANTHROPIC_API_KEY" -}}
  {{- else -}}
    {{- printf "ANTHROPIC_API_KEY" -}}
  {{- end -}}
{{- end -}}

{{/*
Validate provider selections. Call this from configmap.yaml to fail fast on misconfiguration.
*/}}
{{- define "agent-backend.validateProviders" -}}
  {{- $inferenceProvider := .Values.inference.provider -}}
  {{- $embeddingsProvider := .Values.embeddings.provider -}}
  {{- $sandboxProvider := .Values.sandbox.provider -}}

  {{- if not $inferenceProvider -}}
    {{- fail "inference.provider is required. Set it to one of: bedrock, anthropic" -}}
  {{- else if not (has $inferenceProvider (list "bedrock" "anthropic")) -}}
    {{- fail (printf "inference.provider %q is not supported. Must be one of: bedrock, anthropic" $inferenceProvider) -}}
  {{- end -}}

  {{- if and $embeddingsProvider (not (has $embeddingsProvider (list "bedrock"))) -}}
    {{- fail (printf "embeddings.provider %q is not supported. Must be: bedrock" $embeddingsProvider) -}}
  {{- end -}}

  {{- if and $sandboxProvider (not (has $sandboxProvider (list "bedrock"))) -}}
    {{- fail (printf "sandbox.provider %q is not supported. Must be: bedrock" $sandboxProvider) -}}
  {{- end -}}

  {{- if eq $inferenceProvider "anthropic" -}}
    {{- if not (or .Values.anthropic.apiKey .Values.anthropic.existingSecretName) -}}
      {{- fail "inference.provider is \"anthropic\" but neither anthropic.apiKey nor anthropic.existingSecretName is set" -}}
    {{- end -}}
  {{- end -}}

{{- end -}}

{{/*
Return the name of the secret containing the token encryption key.
*/}}
{{- define "agent-backend.tokenEncryptionKey.existingSecret" -}}
  {{- printf "%s" (tpl .Values.tokenEncryptionKeyExistingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.tokenEncryptionKey.existingSecret.secretName" -}}
  {{- include "agent-backend.tokenEncryptionKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.tokenEncryptionKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.tokenEncryptionKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.tokenEncryptionKeyExistingSecretKey .) | default "AGENT_BACKEND_TOKEN_ENCRYPTION_KEY" -}}
  {{- else -}}
    {{- printf "AGENT_BACKEND_TOKEN_ENCRYPTION_KEY" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the Redis URI for the wait-for-redis init container.
*/}}
{{- define "agent-backend.redis.uri" -}}
  {{- printf "%s://%s:%d"
  (ternary "rediss" "redis" (.Values.redis.enableTls | toString | eq "true"))
  (tpl .Values.redis.host .)
  (.Values.redis.port | int)
  -}}
{{- end -}}

{{/*
Return the name of the secret containing the Redis password.
*/}}
{{- define "agent-backend.redis.existingSecret" -}}
  {{- printf "%s" (tpl .Values.redis.existingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.redis.existingSecret.secretName" -}}
  {{- include "agent-backend.redis.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.redis.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.redis.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.redis.existingSecretKey .) | default "AGENT_BACKEND_REDIS_PASSWORD" -}}
  {{- else -}}
    {{- printf "AGENT_BACKEND_REDIS_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Generate or retrieve the token encryption key (Fernet-compatible: URL-safe base64 of 32 random bytes).
Priority: 1) user-provided value, 2) existing secret in cluster, 3) auto-generate.
Result is base64-encoded (for use in Secret data).
*/}}
{{- define "agent-backend.tokenEncryptionKey.value" -}}
  {{- $secretName := include "agent-backend.tokenEncryptionKey.existingSecret.secretName" . -}}
  {{- $secretKey := include "agent-backend.tokenEncryptionKey.existingSecret.secretKey" . -}}
  {{- if .Values.tokenEncryptionKey -}}
    {{- .Values.tokenEncryptionKey | b64enc | quote -}}
  {{- else -}}
    {{- $secretData := (lookup "v1" "Secret" (include "common.names.namespace" .) $secretName).data -}}
    {{- if and $secretData (hasKey $secretData $secretKey) -}}
      {{- index $secretData $secretKey | quote -}}
    {{- else -}}
      {{- randBytes 32 | replace "+" "-" | replace "/" "_" | b64enc | quote -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return this chart's primary ingress hostname. See parent platform chart's `_helpers.tpl` for
usage notes — `'{{ include "seqera.ingress.host" . }}'` in `global.ingress.annotations` resolves
to each chart's own domain at render time.
*/}}
{{- define "seqera.ingress.host" -}}
{{- tpl .Values.global.agentBackendDomain . -}}
{{- end -}}
