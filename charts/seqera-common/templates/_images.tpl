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
Resolve a cloud-provider-specific image override. Returns the fully-qualified image string if an
override is found under .global.azure.images.<cloudProviderImageKey>, or an empty string otherwise.
Fields (registry, image, tag, digest) are evaluated as templates.

{{ include "seqera.images.cloudProviderOverride" ( dict "global" .Values.global "chart" .Chart "cloudProviderImageKey" "platformBackend" "context" $ ) }}
*/}}
{{- define "seqera.images.cloudProviderOverride" -}}
  {{- if and .global .cloudProviderImageKey -}}
    {{- $azureImages := (((.global).azure).images) -}}
    {{- if $azureImages -}}
      {{- $candidate := index $azureImages .cloudProviderImageKey -}}
      {{- if and $candidate ($candidate).image -}}
        {{- $registry := $candidate.registry -}}
        {{- $repository := $candidate.image -}}
        {{- $tag := $candidate.tag -}}
        {{- $digest := $candidate.digest -}}
        {{- if .context -}}
          {{- if $registry -}}
            {{- $registry = tpl (toString $registry) .context -}}
          {{- end -}}
          {{- $repository = tpl (toString $repository) .context -}}
          {{- if $tag -}}
            {{- $tag = tpl (toString $tag) .context -}}
          {{- end -}}
          {{- if $digest -}}
            {{- $digest = tpl (toString $digest) .context -}}
          {{- end -}}
        {{- end -}}
        {{- $overrideImageRoot := dict "registry" $registry "repository" $repository "tag" $tag "digest" $digest -}}
        {{- include "common.images.image" (dict "imageRoot" $overrideImageRoot "global" .global "chart" .chart) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Return the proper image name, giving higher priority to cloud-provider-specific values under
.global. For example, if the user has defined .Values.global.azure.images.platformBackend.image, it
will be used instead of .Values.backend.image when deploying on Azure.

Requires a "cloudProviderImageKey" parameter to identify which cloud-provider image override to look
up (e.g. "platformBackend").

{{ include "seqera.images.image" ( dict "imageRoot" .Values.path.to.the.image "global" .Values.global "chart" .Chart "cloudProviderImageKey" "platformBackend" "context" $ ) }}
*/}}
{{- define "seqera.images.image" -}}
  {{- $cloudOverride := include "seqera.images.cloudProviderOverride" . -}}
  {{- if $cloudOverride -}}
    {{- $cloudOverride -}}
  {{- else -}}
    {{- include "common.images.image" (dict "imageRoot" .imageRoot "global" .global "chart" .chart) -}}
  {{- end -}}
{{- end -}}
