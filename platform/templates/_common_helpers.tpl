{{/* Check if a chart name is contained inside a release, and return the release if so, or return
     the concatenation <releaseName>.<chartName>, to mimic what common.names.fullname does.
     Useful when working on child charts, which change their fullname depending on the parent chart.
     E.g. if you install the release 'tower-with-mysql8', the mysql fullname will return just the
     release name, because 'mysql' is already stored inside the release.

     Example usage:
     {{ include "fullnameForChart" (dict "chartName" "mysql" "releaseName" .Release.Name) }}
*/}}
{{- define "fullnameForChart" -}}
{{- if contains .chartName .releaseName -}}
  {{- .releaseName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- printf "%s-%s" .releaseName .chartName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Construct the image PullSecret if credentials are defined in values file. */}}
{{/* TODO: maybe create a boolean _is_pullSecret_defined so it's easier to check for existence? */}}
{{- define "imagePullSecret" -}}
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
