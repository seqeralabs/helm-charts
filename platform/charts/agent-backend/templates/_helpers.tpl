{{/*
Expand the name of the chart.
*/}}
{{- define "agent-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "agent-backend.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "agent-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent-backend.labels" -}}
helm.sh/chart: {{ include "agent-backend.chart" . }}
{{ include "agent-backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agent-backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: agent-backend
{{- end }}

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
  {{- printf "%s" (tpl .Values.agentBackend.anthropicApiKey.existingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.anthropicApiKey.existingSecret.secretName" -}}
  {{- include "agent-backend.anthropicApiKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.anthropicApiKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.anthropicApiKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.agentBackend.anthropicApiKey.existingSecretKey .) | default "ANTHROPIC_API_KEY" -}}
  {{- else -}}
    {{- printf "ANTHROPIC_API_KEY" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the LangChain API key.
*/}}
{{- define "agent-backend.langchainApiKey.existingSecret" -}}
  {{- printf "%s" (tpl .Values.agentBackend.langchainApiKey.existingSecretName .) -}}
{{- end -}}
{{- define "agent-backend.langchainApiKey.existingSecret.secretName" -}}
  {{- include "agent-backend.langchainApiKey.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "agent-backend.langchainApiKey.existingSecret.secretKey" -}}
  {{- if (include "agent-backend.langchainApiKey.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.agentBackend.langchainApiKey.existingSecretKey .) | default "LANGCHAIN_API_KEY" -}}
  {{- else -}}
    {{- printf "LANGCHAIN_API_KEY" -}}
  {{- end -}}
{{- end -}}