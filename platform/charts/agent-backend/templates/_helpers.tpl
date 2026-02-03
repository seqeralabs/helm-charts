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
  {{- printf "%s" (tpl .Values.agentBackend.anthropicApiKeyExistingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.anthropicApiKey.existingSecret.secretName" -}}
  {{- include "agent-backend.anthropicApiKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.anthropicApiKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.anthropicApiKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.agentBackend.anthropicApiKeyExistingSecretKey .) | default "ANTHROPIC_API_KEY" -}}
  {{- else -}}
    {{- printf "ANTHROPIC_API_KEY" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the LangChain API key.
*/}}
{{- define "agent-backend.langchainApiKey.existingSecret" -}}
  {{- printf "%s" (tpl .Values.agentBackend.langchainApiKeyExistingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.langchainApiKey.existingSecret.secretName" -}}
  {{- include "agent-backend.langchainApiKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.langchainApiKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.langchainApiKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.agentBackend.langchainApiKeyExistingSecretKey .) | default "LANGCHAIN_API_KEY" -}}
  {{- else -}}
    {{- printf "LANGCHAIN_API_KEY" -}}
  {{- end -}}
{{- end -}}