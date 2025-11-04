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
Merge multiple maps into a single map after rendering them with seqera.tplvalues.render.
Merge precedence is consistent with http://masterminds.github.io/sprig/dicts.html#merge-mustmerge
(earlier maps have higher precedence).
Returns a YAML string representation of the merged map.

Usage: {{ include "seqera.tplvalues.merge" (dict "values" (list .Values.map1 .Values.map2) "context" .) }}

Example:
  values: [
    {key1: "value1", key2: "overridden"},
    {key2: "value2", key3: "value3"}
  ]
  Result: {key1: "value1", key2: "overridden", key3: "value3"}
*/}}
{{- define "seqera.tplvalues.merge" -}}
{{- $dst := dict -}}
{{- range .values -}}
{{- $dst = include "seqera.tplvalues.render" (dict "value" . "context" $.context "scope" $.scope) | fromYaml | merge $dst -}}
{{- end -}}
{{ $dst | toYaml }}
{{- end -}}

{{/*
Kubernetes standard labels with automatic type preservation (numbers as integers).
This is a wrapper around common.labels.standard that uses seqera.tplvalues.render
to ensure numeric strings are converted to integers.

Usage: {{ include "seqera.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) }}

Example:
  customLabels:
    app.kubernetes.io/version: "1.2.3"
    custom.label/port: "8080"
    custom.label/name: "my-app"

  Result:
    app.kubernetes.io/name: platform
    helm.sh/chart: platform-1.0.0
    app.kubernetes.io/instance: my-release
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: "1.2.3"
    custom.label/port: 8080
    custom.label/name: "my-app"
*/}}
{{- define "seqera.labels.standard" -}}
{{- $commonLabels := include "common.labels.standard" . | fromYaml -}}
{{- include "seqera.tplvalues.render" (dict "value" $commonLabels "context" .context) -}}
{{- end -}}
