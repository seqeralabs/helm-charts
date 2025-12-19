{{/*
 Copyright (c) 2025 Seqera Labs
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
  {{- printf "%s" (tpl .Values.database.existingSecretKey $) | default "SWELL_DB_PASSWORD" -}}
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
  {{- printf "%s" (tpl .Values.platformDatabase.existingSecretKey $) | default "TOWER_DB_PASSWORD" -}}
{{- end -}}

{{/*
Common initContainer to wait for MySQL database to be ready.

Usually one of:
{{ include "pipeline-optimization.initContainerWaitForMySQL" (dict "name" "pipeline-optimization-db" "waitValues" .Values.initContainerDependencies.waitForMySQL "connDetails" .Values.database         "secretNameTemplate" "pipeline-optimization.database.secretName"         "secretNameKey" "pipeline-optimization.database.secretKey"         "context" $) }}
{{ include "pipeline-optimization.initContainerWaitForMySQL" (dict "name" "platform-db"              "waitValues" .Values.initContainerDependencies.waitForMySQL "connDetails" .Values.platformDatabase "secretNameTemplate" "pipeline-optimization.platformDatabase.secretName" "secretNameKey" "pipeline-optimization.platformDatabase.secretKey" "context" $) }}
*/}}
{{- define "pipeline-optimization.initContainerWaitForMySQL" -}}
- name: wait-for-{{ .name }}
  image: {{ include "common.images.image" (dict "imageRoot" .waitValues.image "global" .context.global) }}
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
          key: {{ include .secretNameKey .context }}
  securityContext: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" .waitValues.resources) | nindent 4 }}
{{- end -}}

{{/*
Custom service account name.
*/}}
{{- define "pipeline-optimization.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end -}}


{{/*
Generate base64-encoded Docker config JSON for image pull secrets from global.imageCredentials.
Each credential needs: registry, username, password, and optionally email.

Usage: {{ include "seqera.images.pullSecretCredentials" . }}
*/}}
{{- define "seqera.images.pullSecretCredentials" -}}
  {{- if .Values.global.imageCredentials -}}
    {{ $regs := list }}
    {{- range .Values.global.imageCredentials -}}
      {{- if and .registry .username .password .email -}}
      {{- $regs = append $regs (printf "\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc)) -}}
      {{- else if and .registry .username .password -}}
      {{- $regs = append $regs (printf "\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}" .registry .username .password (printf "%s:%s" .username .password | b64enc)) -}}
      {{- end -}}
    {{- end -}}
    {{- printf "{\"auths\":{%s}}" (join "," $regs) | b64enc -}}
  {{- end -}}
{{- end -}}
{{/*
Recursively render values with template evaluation and automatic type preservation.
Evaluates template strings (containing {{}}) and converts numeric strings to integers.

Type handling:
- "{{...}}" strings: Evaluated, integers auto-converted
- Numeric strings: Converted to integers ("8088" → 8088)
- Maps/slices: Recursively processed
- Other types: Rendered via toYaml

Usage: {{ include "seqera.tplvalues.render" (dict "value" .Values.some.value "context" $) }}

Examples:
"8080"                          → 8080
"{{ .Values.port }}"            → (evaluated and type-converted)
{port: "8080", path: "/health"} → {port: 8080, path: "/health"}
*/}}
{{- define "seqera.tplvalues.render" -}}
  {{- if kindIs "string" .value -}}
    {{- if contains "{{" .value -}}
      {{- $rendered := tpl .value .context -}}
      {{- if regexMatch "^-?[0-9]+$" $rendered -}}
      {{- $rendered | atoi -}}
      {{- else -}}
      {{- $rendered -}}
      {{- end -}}
    {{- else if regexMatch "^-?[0-9]+$" .value -}}
    {{- .value | atoi -}}
    {{- else -}}
    {{- .value -}}
    {{- end -}}
  {{- else if kindIs "map" .value -}}
  {{- include "seqera.tplvalues.renderMap" (dict "value" .value "context" .context) -}}
  {{- else if kindIs "slice" .value -}}
  {{- include "seqera.tplvalues.renderSlice" (dict "value" .value "context" .context) -}}
  {{- else -}}
  {{- .value | toYaml -}}
  {{- end -}}
{{- end -}}

{{- define "seqera.tplvalues.renderMap" -}}
  {{- $dict := dict -}}
  {{- range $k, $v := .value -}}
    {{- if kindIs "string" $v -}}
      {{- if contains "{{" $v -}}
        {{- $rendered := tpl $v $.context -}}
        {{- if regexMatch "^-?[0-9]+$" $rendered -}}
          {{- $_ := set $dict $k ($rendered | atoi) -}}
        {{- else -}}
          {{- $_ := set $dict $k $rendered -}}
        {{- end -}}
      {{- else if regexMatch "^-?[0-9]+$" $v -}}
        {{- $_ := set $dict $k ($v | atoi) -}}
      {{- else -}}
        {{- $_ := set $dict $k $v -}}
      {{- end -}}
    {{- else if kindIs "map" $v -}}
      {{- $nested := include "seqera.tplvalues.renderMapToDict" (dict "value" $v "context" $.context) | fromYaml -}}
      {{- $_ := set $dict $k $nested -}}
    {{- else if kindIs "slice" $v -}}
      {{- $wrappedYaml := printf "list:\n%s" (include "seqera.tplvalues.renderSliceToList" (dict "value" $v "context" $.context) | nindent 2) -}}
      {{- $parsed := $wrappedYaml | fromYaml -}}
      {{- $_ := set $dict $k $parsed.list -}}
    {{- else -}}
      {{- $_ := set $dict $k $v -}}
    {{- end -}}
  {{- end -}}
{{- $dict | toYaml -}}
{{- end -}}

{{- define "seqera.tplvalues.renderMapToDict" -}}
  {{- $dict := dict -}}
  {{- range $k, $v := .value -}}
    {{- if kindIs "string" $v -}}
      {{- if contains "{{" $v -}}
        {{- $rendered := tpl $v $.context -}}
        {{- if regexMatch "^-?[0-9]+$" $rendered -}}
          {{- $_ := set $dict $k ($rendered | atoi) -}}
        {{- else -}}
          {{- $_ := set $dict $k $rendered -}}
        {{- end -}}
      {{- else if regexMatch "^-?[0-9]+$" $v -}}
        {{- $_ := set $dict $k ($v | atoi) -}}
      {{- else -}}
        {{- $_ := set $dict $k $v -}}
      {{- end -}}
    {{- else if kindIs "map" $v -}}
      {{- $nested := include "seqera.tplvalues.renderMapToDict" (dict "value" $v "context" $.context) | fromYaml -}}
      {{- $_ := set $dict $k $nested -}}
    {{- else if kindIs "slice" $v -}}
      {{- $wrappedYaml := printf "list:\n%s" (include "seqera.tplvalues.renderSliceToList" (dict "value" $v "context" $.context) | nindent 2) -}}
      {{- $parsed := $wrappedYaml | fromYaml -}}
      {{- $_ := set $dict $k $parsed.list -}}
    {{- else -}}
      {{- $_ := set $dict $k $v -}}
    {{- end -}}
  {{- end -}}
{{- $dict | toYaml -}}
{{- end -}}

{{- define "seqera.tplvalues.renderSlice" -}}
  {{- $list := list -}}
  {{- range .value -}}
    {{- if kindIs "string" . -}}
      {{- if contains "{{" . -}}
        {{- $rendered := tpl . $.context -}}
        {{- if regexMatch "^-?[0-9]+$" $rendered -}}
        {{- $list = append $list ($rendered | atoi) -}}
        {{- else -}}
        {{- $list = append $list $rendered -}}
        {{- end -}}
      {{- else if regexMatch "^-?[0-9]+$" . -}}
      {{- $list = append $list (. | atoi) -}}
      {{- else -}}
      {{- $list = append $list . -}}
      {{- end -}}
    {{- else if kindIs "map" . -}}
      {{- $nested := include "seqera.tplvalues.renderMapToDict" (dict "value" . "context" $.context) | fromYaml -}}
    {{- $list = append $list $nested -}}
    {{- else if kindIs "slice" . -}}
      {{- $nested := include "seqera.tplvalues.renderSliceToList" (dict "value" . "context" $.context) | fromYaml -}}
    {{- $list = append $list $nested -}}
    {{- else -}}
    {{- $list = append $list . -}}
    {{- end -}}
  {{- end -}}
{{- $list | toYaml -}}
{{- end -}}

{{- define "seqera.tplvalues.renderSliceToList" -}}
  {{- $list := list -}}
  {{- range .value -}}
    {{- if kindIs "string" . -}}
      {{- if contains "{{" . -}}
        {{- $rendered := tpl . $.context -}}
        {{- if regexMatch "^-?[0-9]+$" $rendered -}}
        {{- $list = append $list ($rendered | atoi) -}}
        {{- else -}}
        {{- $list = append $list $rendered -}}
        {{- end -}}
      {{- else if regexMatch "^-?[0-9]+$" . -}}
      {{- $list = append $list (. | atoi) -}}
      {{- else -}}
      {{- $list = append $list . -}}
      {{- end -}}
    {{- else if kindIs "map" . -}}
      {{- $nested := include "seqera.tplvalues.renderMapToDict" (dict "value" . "context" $.context) | fromYaml -}}
    {{- $list = append $list $nested -}}
    {{- else if kindIs "slice" . -}}
      {{- $nested := include "seqera.tplvalues.renderSliceToList" (dict "value" . "context" $.context) | fromYaml -}}
    {{- $list = append $list $nested -}}
    {{- else -}}
    {{- $list = append $list . -}}
    {{- end -}}
  {{- end -}}
{{- $list | toYaml -}}
{{- end -}}
