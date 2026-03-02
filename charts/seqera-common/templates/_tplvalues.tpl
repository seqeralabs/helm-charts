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

{{/*
Render environment variables ensuring all values are strings.
This is necessary because Kubernetes requires env var values to be strings,
but YAML parsers may interpret numeric values as integers.

Usage: {{ include "seqera.envVars.render" (dict "value" .Values.backend.extraEnvVars "context" $) }}

This helper ensures that:
- All env var values are quoted as strings (required by Kubernetes)
- Template expressions in values are evaluated
- valueFrom references work correctly
*/}}
{{- define "seqera.envVars.render" -}}
  {{- if kindIs "slice" .value -}}
    {{- range .value -}}
      {{- $envVar := . -}}
      {{- if kindIs "map" $envVar }}
- name: {{ tpl (toString $envVar.name) $.context }}
        {{- if hasKey $envVar "value" }}
  value: {{ tpl (toString $envVar.value) $.context | quote }}
        {{- else if hasKey $envVar "valueFrom" }}
  valueFrom: {{- include "common.tplvalues.render" (dict "value" $envVar.valueFrom "context" $.context) | nindent 4 }}
        {{- end }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
