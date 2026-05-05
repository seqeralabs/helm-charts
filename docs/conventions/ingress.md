# Ingress Conventions

How Ingress resources are structured across the `platform` chart and its
subcharts (`studios`, `portal-web`, `mcp`, `wave`, `agent-backend`).

The goal is consistency: every chart that exposes HTTP traffic ships the same
Ingress shape so users only have to learn one set of values.

## One Ingress per chart

Each chart that exposes HTTP traffic owns exactly one `templates/ingress.yaml`.
Subcharts do not share an Ingress with the parent — each component is
independently toggleable via its own `ingress.enabled`.

When adding a new chart that needs HTTP exposure, copy the structure from an
existing template (e.g. `charts/platform/charts/wave/templates/ingress.yaml`)
rather than inventing a new shape.

## Standard structure

Every Ingress template follows the same skeleton:

```gotemplate
{{ if or .Values.ingress.enabled .Values.global.ingress.enabled }}
  {{- $commonLabels := include "common.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) | fromYaml -}}
  {{- $mergedlabels := include "common.tplvalues.merge" (dict "values" (list .Values.ingress.extraLabels $commonLabels) "context" .) -}}
  {{- $labels := include "common.tplvalues.render" (dict "value" $mergedlabels "context" $) -}}
  {{- $mergedAnnotations := include "common.tplvalues.merge" (dict "values" (list .Values.ingress.annotations .Values.commonAnnotations) "context" .) -}}
  {{- $annotations := include "common.tplvalues.render" (dict "value" $mergedAnnotations "context" $) -}}
  {{- $defaultPathType := default .Values.global.ingress.defaultPathType .Values.ingress.defaultPathType -}}
  {{- $path := default .Values.global.ingress.path .Values.ingress.path -}}
  {{- $ingressClassName := default .Values.global.ingress.ingressClassName .Values.ingress.ingressClassName -}}

apiVersion: {{ include "common.capabilities.ingress.apiVersion" . }}
kind: Ingress
metadata:
  name: {{ include "common.names.fullname" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels: {{- $labels | nindent 4 }}
  annotations: {{- $annotations | nindent 4 }}
spec:
  {{- with .Values.ingress.defaultBackend }}
  defaultBackend: {{- include "seqera.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}

  {{- if $ingressClassName }}
  ingressClassName: {{ $ingressClassName | quote }}
  {{- end }}

  {{- with .Values.ingress.tls }}
  tls: {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}

  rules:
    - host: {{ tpl .Values.global.<chartDomain> . | quote }}
      http:
        paths:
          - path: {{ $path | quote }}
            pathType: {{ $defaultPathType }}
            backend:
              service:
                name: {{ (include "common.names.fullname" .) | quote }}
                port:
                  number: {{ tpl (toString .Values.service.http.port) . | int }}

  {{- range .Values.ingress.extraHosts }}
    - host: {{ tpl .host $ | quote }}
      http:
        paths:
    {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType | default $defaultPathType }}
            backend:
              service:
                name: {{ tpl .serviceName $ | quote }}
                port:
                  number: {{ tpl (toString .portNumber) $ | int }}
    {{- end }}
  {{- end }}
{{- end }}
```

The pieces that should not change between charts:

- **Gate**: `{{ if or .Values.ingress.enabled .Values.global.ingress.enabled }}` —
  disabled by default; flipping `global.ingress.enabled: true` enables every
  chart's Ingress at once.
- **API version**: resolved via `common.capabilities.ingress.apiVersion`, never
  hard-coded.
- **Name / namespace**: `common.names.fullname` and `common.names.namespace`.
- **Labels**: standard labels merged with `commonLabels` and
  `ingress.extraLabels`, then `tpl`-rendered.
- **Annotations**: `commonAnnotations` merged with `ingress.annotations`, then
  `tpl`-rendered.
- **`defaultBackend`, `ingressClassName`, `tls`**: optional, all rendered
  through the same `tpl` helper so values can reference `.Release` etc.
- **`extraHosts`**: every chart accepts the same `extraHosts` shape so users
  can add hostnames without forking the chart.

## Hostnames live in `global`

Primary hostnames are pulled from `.Values.global.*Domain` so the parent chart
and its subcharts can be wired up without duplicating values. Examples in use:

| Chart           | Host source                                                                    |
| --------------- | ------------------------------------------------------------------------------ |
| `platform`      | `global.platformExternalDomain`, `global.contentDomain` (optional second host) |
| `studios`       | `global.studiosDomain` (wildcard `*.<domain>`)                                 |
| `portal-web`    | `global.portalWebDomain`                                                       |
| `wave`          | `global.waveDomain`                                                            |
| `mcp`           | `global.mcpDomain`                                                             |
| `agent-backend` | `global.agentBackendDomain`                                                    |

Hosts are always passed through `tpl` so they can reference other values
(e.g. `'{{ printf "*.%s" .Values.global.studiosDomain }}'`).

When adding a new chart, define a new `global.<name>Domain` value rather than
introducing a chart-local `ingress.host`.

## Backend service wiring

The default rule's backend points at the chart's own Service, named via
`common.names.fullname`. Two patterns appear:

- **Single-service charts** (`portal-web`, `wave`, `mcp`, `agent-backend`):
  backend is `{{ include "common.names.fullname" . }}`.
- **Multi-service charts** (`platform`, `studios`): backend is suffixed —
  `{{ printf "%s-frontend" (include "common.names.fullname" .) }}` for
  `platform`, `-proxy` for `studios`.

Ports are read from the relevant Service values block (e.g.
`.Values.frontend.service.http.port`) and always rendered with
`{{ tpl (toString ...) . | int }}` so templated ports survive the cast.

## Cluster-wide ingress defaults via `global.ingress`

In practice, users who expose one Seqera service via Ingress almost always expose
them all the same way: same controller, same class name, same annotations
(cert-manager, ALB scheme, NGINX body-size limits, etc.). Forcing those values
to be repeated under `platform.ingress.*`, `studios.ingress.*`, `wave.ingress.*`,
and so on is verbose and drift-prone. `global.ingress` lifts the controller-wide
concerns to one place; per-chart overrides remain available for the rare case
where one service genuinely needs different routing.

Seven fields are controller-wide concerns rather than per-chart settings:

| Field              | Local default | Global default | Resolution                                                       |
| ------------------ | ------------- | -------------- | ---------------------------------------------------------------- |
| `enabled`          | `false`       | `false`        | OR — either being `true` enables the Ingress                     |
| `path`             | `""`          | `"/"`          | Local wins when set; otherwise global. ALB → `"/*"`              |
| `defaultPathType`  | `""`          | `"Prefix"`     | Local wins when set; otherwise global                            |
| `ingressClassName` | `""`          | `""`           | Local wins when set; otherwise global                            |
| `annotations`      | `{}`          | `{}`           | Merged; local wins on key collision (e.g. cert-manager, ALB SSL) |
| `extraLabels`      | `{}`          | `{}`           | Merged; local wins on key collision                              |
| `tls`              | `[]`          | `[]`           | Concatenated — supports a single wildcard cert across charts     |

Set these once at the parent's `global.ingress.*` and every subchart's Ingress
picks them up. Three resolution patterns:

- **OR** for `enabled` so flipping `global.ingress.enabled: true` turns on
  every chart's Ingress in one switch.
- **Local-wins-when-set** for the scalar fields (`path`, `defaultPathType`,
  `ingressClassName`) so a chart can opt out of the cluster-wide default
  without disabling it for everyone.
- **Merge / concat** for the collection fields (`annotations`, `extraLabels`,
  `tls`) so cluster-wide entries (cert-manager issuer, NGINX `proxy-body-size`,
  wildcard cert) coexist with chart-specific additions.

In templates the resolution is done once at the top:

```gotemplate
{{- $defaultPathType := default .Values.global.ingress.defaultPathType .Values.ingress.defaultPathType -}}
{{- $path := default .Values.global.ingress.path .Values.ingress.path -}}
{{- $ingressClassName := default .Values.global.ingress.ingressClassName .Values.ingress.ingressClassName -}}
{{- $tls := concat (default (list) .Values.ingress.tls) (default (list) .Values.global.ingress.tls) -}}
```

`annotations` and `extraLabels` are merged inline as part of the existing
`common.tplvalues.merge` chain — the global is added to the list of sources,
positioned so local entries win on key collision.

## The `seqera.ingress.host` helper

Each chart's `_helpers.tpl` defines a template called `seqera.ingress.host`
that returns that chart's primary domain (`global.platformExternalDomain` for
platform, `global.studiosDomain` for studios, etc.). The point of having the
same template name everywhere is that users can write a single annotation in
`global.ingress.annotations` that resolves to the right hostname per chart:

```yaml
global:
  ingress:
    annotations:
      external-dns.alpha.kubernetes.io/hostname: '{{ include "seqera.ingress.host" . }}'
```

When the platform chart renders its Ingress, the include resolves to
`platform.example.com`. When studios renders, the same string resolves to
`studios.example.com`. No hard-coding required, and it composes — for a
wildcard form, write `'\*.{{ include "seqera.ingress.host" . }}'`.

When adding a new chart, define `seqera.ingress.host` in its `_helpers.tpl`
returning the chart's primary domain via `tpl`:

```gotemplate
{{- define "seqera.ingress.host" -}}
{{- tpl .Values.global.<chartDomain> . -}}
{{- end -}}
```

## TLS

`ingress.tls` is an empty list by default. When set, it is rendered through
`common.tplvalues.render` so users can template hostnames:

```yaml
ingress:
  tls:
    - hosts:
        - "{{ .Values.global.platformExternalDomain }}"
      secretName: my-tls
```

TLS secrets are **not** generated by the chart — bring your own (typically
managed by cert-manager or external-secrets).

## Annotations and ingress class

- `ingressClassName` is the supported way to pick a controller. Do **not** use
  the deprecated `kubernetes.io/ingress.class` annotation. Set it once at
  `global.ingress.ingressClassName`; per-chart overrides are rare.
- `ingress.annotations` is merged with `commonAnnotations`. Controller-specific
  config (ALB, nginx, etc.) goes here.

## Required values shape

Every chart's `values.yaml` must expose this block under `ingress:`:

```yaml
ingress:
  enabled: false
  path: ""             # falls back to global.ingress.path
  defaultPathType: ""  # falls back to global.ingress.defaultPathType
  ingressClassName: "" # falls back to global.ingress.ingressClassName
  defaultBackend: {}
  extraHosts: []
  annotations: {}
  extraLabels: {}
  tls: []
```

And in `global:`:

```yaml
global:
  ingress:
    enabled: false
    path: "/"
    defaultPathType: "Prefix"
    ingressClassName: ""
    annotations: {}
    extraLabels: {}
    tls: []
```

Keep the `# --` helm-docs comments on each field — the README is generated
from them.

## Testing

Every Ingress template has a matching `tests/ingress_test.yaml`. Tests should
cover at minimum:

- Resource is **not** rendered when `ingress.enabled: false`.
- A `matchSnapshot` for the default-enabled rendering.
- Targeted `equal` assertions for `ingressClassName`, `tls`, `extraHosts`, and
  any chart-specific host logic (e.g. the optional `contentDomain` rule in
  `platform`, the wildcard host in `studios`).

Follow the test rules in [CLAUDE.md](../../CLAUDE.md) — assert on whole
maps/lists, not individual fields.
