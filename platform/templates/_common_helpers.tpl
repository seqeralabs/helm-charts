{{/*
Generate base64-encoded Docker config JSON for image pull secrets from global.imageCredentials.
Each credential needs: registry, username, password, and optionally email.

Usage: {{ include "seqera.images.pullSecretCredentials" . }}

TODO: maybe create a boolean _is_pullSecret_defined so it's easier to check for existence?
TODO: does it make sense to not scope this template, since templates are shared between the chart and its subcharts? would it make things harder to maintain if the subcharts redefine this template?
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
      {{- $rendered | quote -}}
    {{- end -}}
  {{- else if regexMatch "^-?[0-9]+$" .value -}}
    {{- .value | atoi -}}
  {{- else -}}
    {{- .value | quote -}}
  {{- end -}}
{{- else if kindIs "map" .value -}}
  {{- print "{" -}}
  {{- $first := true -}}
  {{- range $k, $v := .value -}}
    {{- if not $first -}}{{- print "," -}}{{- end -}}
    {{- $first = false -}}
    {{- $k | quote -}}
    {{- print ":" -}}
    {{- include "seqera.tplvalues.render" (dict "value" $v "context" $.context) -}}
  {{- end -}}
  {{- print "}" -}}
{{- else if kindIs "slice" .value -}}
  {{- print "[" -}}
  {{- $first := true -}}
  {{- range .value -}}
    {{- if not $first -}}{{- print "," -}}{{- end -}}
    {{- $first = false -}}
    {{- include "seqera.tplvalues.render" (dict "value" . "context" $.context) -}}
  {{- end -}}
  {{- print "]" -}}
{{- else -}}
  {{- .value | toYaml -}}
{{- end -}}
{{- end -}}
