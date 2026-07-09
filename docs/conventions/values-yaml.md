# values.yaml Conventions

How `values.yaml` files are commented and structured across the `platform`
chart and its subcharts.

The goal is consistency: every chart documents its values the same way so
the generated README tables read uniformly and contributors don't have to
guess at the format.

## Tooling

We use [`helm-docs`](https://github.com/norwoodj/helm-docs) to generate the
values table in each chart's `README.md` from `README.md.gotmpl`. This is
run automatically by the pre-commit hook.

Helm-docs reads `# --` prefixed comments. Plain `#` comments are ignored
by the tool and are for human readers only.

Each chart's `README.md.gotmpl` uses a **custom Markdown loop** over
`.Sections.Sections` (and `.Sections.DefaultSection`) instead of the
default `chart.valuesSection` (which is flat) or `chart.valuesSectionHtml`
(which emits raw HTML tables). The custom loop renders one Markdown table
per section with proper headings — diff-friendly and readable in plain
text. When adding a new chart, copy the values block from an existing
`README.md.gotmpl` rather than calling `chart.valuesSection` directly.

We deliberately do **not** use Bitnami's `## @param` / `## @section`
annotation style. That syntax is consumed by
[`readme-generator-for-helm`](https://github.com/bitnami/readme-generator-for-helm),
a different tool. The patterns below adopt Bitnami's _practices_ —
sectioning, inline examples, ref links, conflict notes — but expressed in
helm-docs syntax.

## Anatomy of a documented value

```yaml
# -- Domain where Seqera Platform listens
platformExternalDomain: example.com
```

Rules:

- `# --` comment sits **immediately above** the key, no blank line between.
- Description is a single sentence, ends without a period unless multiple
  sentences.
- Helm-docs strips the `--` and renders the rest as the description column.

### Multi-line descriptions

Continue with a plain `#` on subsequent lines. Helm-docs concatenates them
into one description.

```yaml
# -- Domain where user-created Platform reports are exposed, to avoid
# Cross-Site Scripting (XSS) attacks. If unset, data is served through the
# main domain `.global.platformExternalDomain`. Evaluated as a template
contentDomain: '{{ printf "user-data.%s" .Values.global.platformExternalDomain }}'
```

### Templated values

When a value is evaluated as a Go template at render time, end the
description with `Evaluated as a template`. This is a load-bearing signal
to operators that they can reference other values inside the string.

### Default overrides

When the literal default in the file is misleading (e.g. a sentinel, a
computed value, or `nil` that resolves to something), use `# @default --`:

```yaml
# -- Image tag for the Platform backend.
# @default -- the chart's `appVersion`
tag:
```

### Skipping a key

To exclude an internal key from the generated table, omit the `# --`
comment entirely, or use `# @ignored` if you still want a human comment.

## Sectioning

Helm-docs supports `# @section -- Name` to group values in the README.
**Important:** unlike Bitnami's `## @section`, this is **per-value, not a
boundary**. Every value needs its own annotation or it falls into an
"Other Values" catch-all.

The rule: **annotate every value**. Yes, it's repetitive. No, there is no
workaround — partial adoption produces a top-heavy "Other Values" bucket
and the table becomes harder to read, not easier. The
[Grafana k8s-monitoring chart](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/collectors/alloy-values.yaml)
is the canonical example of doing this well in helm-docs.

```yaml
# -- Number of backend replicas
# @section -- Backend deployment
replicaCount: 2
```

### Section names

Section names are unquoted and free-form. Quote only if the name contains
characters YAML would otherwise interpret (rare — spaces and colons are
fine unquoted).

For nesting, use `Parent: Child` naming. Helm-docs has a flat section
model, so this is a convention rather than real hierarchy, but it gives
operators visible grouping in the rendered table:

```yaml
# -- The URL of the remote config server.
# @section -- Remote Configuration
url: ""

# -- The username to use for the remote config server.
# @section -- Remote Configuration: Authentication
username: ""
```

Let sections grow organically with the chart — don't pre-allocate a fixed
list. When a block of related values reaches ~3 entries, give it a
section. When a sub-area inside that block reaches ~3 entries, give it a
`Parent: Child` sub-section.

### Section descriptions

helm-docs (as of v1.14.2) does **not** support per-section descriptions —
the `section` struct exposes only `SectionName` and `SectionItems`. The
`# @sectionDescription` annotation seen in some chart documentation is
not a real feature; ignore it.

If a chart needs prose orientation above a particular section's table,
hand-write that section block in `README.md.gotmpl` instead of relying on
the auto-loop. Use `{{- range .Values }}{{- if hasPrefix "X" .Key }}` to
filter by key prefix, following the
[SurrealDB pattern](https://github.com/surrealdb/helm-charts/pull/17/files):

```gotemplate
## Persistence parameters

Persistent storage configuration. Disabled by default; enable when running
single-replica workloads that need durable state across pod restarts.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
{{- range .Values }}
  {{- if hasPrefix "persistence" .Key }}
| {{ .Key }} | {{ .Type }} | {{ if .Default }}{{ .Default }}{{ else }}{{ .AutoDefault }}{{ end }} | {{ if .Description }}{{ .Description }}{{ else }}{{ .AutoDescription }}{{ end }} |
  {{- end }}
{{- end }}
```

Reserve this for sections where the section name alone leaves operators
guessing. Most sections (Probes, Resources, Service Account, etc.) don't
need it.

## Narrative comments

Plain `#` comments (without `--`) are for human readers of the YAML file
and are ignored by helm-docs. Use them to:

- Explain the _purpose_ of a block before listing its values
- Link upstream documentation
- Show example shapes

```yaml
# Ingress defaults shared across the parent chart and all subcharts. Each
# subchart's local `ingress.*` value takes precedence when set; otherwise
# the global is used.
ingress:
  # -- Default path applied to ingress rules when a chart's local
  # `ingress.path` is not set. AWS ALB users should override to `/*`.
  path: "/"
```

The narrative block above the map describes the _group_; each child key
gets its own `# --` for the table.

## Inline examples

For non-obvious complex types (lists of maps, nested structures), show an
example as commented YAML directly under the value. Bitnami uses `## E.g.`
or `## Example:` — match that.

```yaml
# -- Optional credentials to log in and fetch images from a private
# registry. These credentials are shared with all the subcharts
# automatically
imageCredentials: []
# imageCredentials:
# - registry: ""
#   username: ""
#   password: ""
#   email: someone@example.com  # Optional
```

Examples should be valid YAML that the user could paste in and adjust.

## Reference links

When a value mirrors an upstream Kubernetes / library concept, link it
inline using `# ref: <url>` on the line above the value (or at the top of
the block if it applies to the whole group):

```yaml
# ref: https://kubernetes.io/docs/concepts/services-networking/ingress/
ingress: ...
```

Keep `ref:` lines as plain `#` so they don't pollute the description
column.

## Conflict and precedence notes

When two values interact (one overrides the other, one is ignored when
the other is set, etc.), say so **inside the description**, not in a
separate comment. This keeps the README table self-contained.

```yaml
# -- Existing Secret containing the database password. When set,
# `mysql.password` is ignored.
existingSecretName: ""
```

Bitnami does this consistently and it's the single most useful pattern to
adopt — operators reading the generated table see the relationship
without having to cross-reference the source.

## Deprecation

Mark deprecated values inline, prefixed with `DEPRECATED:` and naming the
replacement:

```yaml
# -- DEPRECATED: use `global.defaultStorageClass` instead
storageClass: ""
```

## File structure

Order keys top-to-bottom by scope, narrowing as you go:

1. License header (Apache-2.0 boilerplate)
2. File-level narrative — what this chart is, how to use the file
3. `global:` — values shared with subcharts
4. Common parameters (`nameOverride`, `commonLabels`, etc.)
5. Component-specific blocks (backend, frontend, cron, ...)
6. External dependencies (mysql, redis, ...)
7. Subchart values (nested under the subchart name)

This matches Bitnami's ordering and keeps the generated README scannable.

## What not to do

- **Don't mix `## @param` Bitnami annotations into our files.** They will
  be silently ignored by helm-docs and the value will be undocumented.
- **Don't put the description after the value.** Helm-docs only reads
  comments _above_ the key.
- **Don't put a blank line between the `# --` description and the key.**
  The blank line breaks the association.
- **Don't add `# --` to obviously self-describing internal scaffolding.**
  If a key has no operator-facing meaning, leave it undocumented rather
  than restating its name.
- **Don't duplicate the value name in the description.** "Backend
  replicas" beats "The replicaCount value for the backend".

## Regenerating the README

```bash
pre-commit run helm-docs --all-files
# or directly
helm-docs --chart-search-root charts/platform
```

The hook is wired into pre-commit; CI will fail if a values.yaml change
isn't accompanied by the regenerated README.
