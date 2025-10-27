{{/*
Construct the image PullSecret if credentials are defined in values file.

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
