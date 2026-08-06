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
Render an Ingress path backend `service` block from an `extraHosts` path entry.

Exactly one of `portName` or `portNumber` must be set. A named port renders as
`port.name` (e.g. to reference an ALB action defined via ingress annotations); a
numeric port renders as `port.number`. If neither is set the template fails, so a
missing port cannot silently produce an invalid `port.number: 0` backend.

All string inputs are evaluated as templates against `context`.

Usage:
{{- include "seqera.ingress.backend" (dict "serviceName" .serviceName "portName" .portName "portNumber" .portNumber "context" $) | nindent 14 }}

Params:
- serviceName - String. Required. Name of the backing service. Template-evaluated.
- portName    - String. Optional. Named service port. Template-evaluated. Mutually exclusive with portNumber.
- portNumber  - String/Int. Optional. Numeric service port. Template-evaluated. Mutually exclusive with portName.
- context     - Dict. Required. Context for template evaluation.
*/}}
{{- define "seqera.ingress.backend" -}}
service:
  name: {{ tpl .serviceName .context | quote }}
  port:
  {{- if .portName }}
    name: {{ tpl .portName .context | quote }}
  {{- else if .portNumber }}
    number: {{ tpl (toString .portNumber) .context | int }}
  {{- else }}
    {{- fail "ingress.extraHosts path entry must define either portName or portNumber" }}
  {{- end }}
{{- end -}}
