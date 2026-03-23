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
{{- define "agent-backend.anthropicApiKey.existingSecret" -}}
  {{- printf "%s" (tpl .Values.anthropicApiKeyExistingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.anthropicApiKey.existingSecret.secretName" -}}
  {{- include "agent-backend.anthropicApiKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.anthropicApiKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.anthropicApiKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.anthropicApiKeyExistingSecretKey .) | default "ANTHROPIC_API_KEY" -}}
  {{- else -}}
    {{- printf "ANTHROPIC_API_KEY" -}}
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
