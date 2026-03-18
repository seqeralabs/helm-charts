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
{{- define "mcp.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end }}

{{/*
Return the name of the secret containing the MCP OAuth JWT seed.
*/}}
{{- define "mcp.oauth.jwt.existingSecret" -}}
  {{- printf "%s" (tpl .Values.oauth.jwtSeedSecretName .) -}}
{{- end -}}
{{- define "mcp.oauth.jwt.existingSecret.secretName" -}}
  {{- include "mcp.oauth.jwt.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "mcp.oauth.jwt.existingSecret.secretKey" -}}
  {{- if (include "mcp.oauth.jwt.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.oauth.jwtSeedSecretKey .) | default "OAUTH_JWT_SECRET" -}}
  {{- else -}}
    {{- printf "OAUTH_JWT_SECRET" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the OIDC client registration token.
*/}}
{{- define "mcp.oidcToken.existingSecret" -}}
  {{- printf "%s" (tpl .Values.oidcToken.existingSecretName .) -}}
{{- end -}}
{{- define "mcp.oidcToken.secretName" -}}
  {{- include "mcp.oidcToken.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}
{{- define "mcp.oidcToken.secretKey" -}}
  {{- if (include "mcp.oidcToken.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.oidcToken.existingSecretKey .) | default "TOWER_OIDC_REGISTRATION_INITIAL_ACCESS_TOKEN" -}}
  {{- else -}}
    {{- printf "TOWER_OIDC_REGISTRATION_INITIAL_ACCESS_TOKEN" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the MCP OAuth client secret.
*/}}
{{- define "mcp.oauth.client.existingSecret" -}}
  {{- printf "%s" (tpl .Values.oauth.clientSecretExistingSecretName .) -}}
{{- end -}}
{{- define "mcp.oauth.client.existingSecret.secretName" -}}
  {{- include "mcp.oauth.client.existingSecret" . | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "mcp.oauth.client.existingSecret.secretKey" -}}
  {{- if (include "mcp.oauth.client.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.oauth.clientSecretExistingSecretKey .) | default "OAUTH_CLIENT_SECRET" -}}
  {{- else -}}
    {{- printf "OAUTH_CLIENT_SECRET" -}}
  {{- end -}}
{{- end -}}
