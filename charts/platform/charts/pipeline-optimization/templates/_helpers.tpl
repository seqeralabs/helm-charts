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
Return the JDBC URL for the database connection, including connection options.
Constructs URL in format: jdbc:mysql://host:port/database?option1=value1&option2=value2

For now this template is built around the only driver that can be set, 'mariadb'.
All database fields support template evaluation using the tpl function.
*/}}
{{- define "pipeline-optimization.platformDatabase.url" -}}
  {{- printf "jdbc:mysql://%s:%s/%s"
  (tpl .Values.platformDatabase.host .)
  (tpl (.Values.platformDatabase.port | toString) .)
  (tpl .Values.platformDatabase.name .) -}}
{{- end -}}

{{/*
Return the name of the secret containing the Platform Optimization database password.
*/}}
{{- define "pipeline-optimization.database.existingSecret" -}}
  {{- printf "%s" (tpl .Values.database.existingSecretName $) -}}
{{- end -}}
{{- define "pipeline-optimization.database.secretName" -}}
  {{- include "pipeline-optimization.database.existingSecret" $ | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "pipeline-optimization.database.secretKey" -}}
  {{- if (include "pipeline-optimization.database.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.database.existingSecretKey $) | default "SWELL_DB_PASSWORD" -}}
  {{- else -}}
    {{- printf "SWELL_DB_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Return the name of the secret containing the Platform database password.
*/}}
{{- define "pipeline-optimization.platformDatabase.existingSecret" -}}
  {{- printf "%s" (tpl .Values.platformDatabase.existingSecretName $) -}}
{{- end -}}
{{- define "pipeline-optimization.platformDatabase.secretName" -}}
  {{- include "pipeline-optimization.platformDatabase.existingSecret" $ | default (include "common.names.fullname" .) -}}
{{- end -}}

{{- define "pipeline-optimization.platformDatabase.secretKey" -}}
  {{- if (include "pipeline-optimization.platformDatabase.existingSecret" .) -}}
    {{- printf "%s" (tpl .Values.platformDatabase.existingSecretKey $) | default "TOWER_DB_PASSWORD" -}}
  {{- else -}}
    {{- printf "TOWER_DB_PASSWORD" -}}
  {{- end -}}
{{- end -}}

{{/*
Custom service account name.
*/}}
{{- define "pipeline-optimization.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end -}}
