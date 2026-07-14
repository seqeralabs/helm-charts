<!--
 Copyright (c) 2025 - 2026 Seqera Labs
 All rights reserved.

 SPDX-License-Identifier: Apache-2.0
-->

# ServiceAccounts

This document lists every Kubernetes `ServiceAccount` the Seqera Platform chart (and its subcharts)
can create, explains how their names are derived, how naming changes between releases, and how to
control creation and naming with the `serviceAccount.*` values.

## Summary

Each chart and subchart owns **exactly one** `ServiceAccount`, rendered from its own
`templates/serviceaccount.yaml`. Workloads never define ServiceAccounts inline — they only
reference one via `serviceAccountName`. A subchart's ServiceAccount is only created when that
subchart is enabled (via its `*.enabled` condition in the parent `Chart.yaml`).

| Chart / subchart        | Enabled by                       | Generated ServiceAccount name¹    | Workloads that use it                          |
| ----------------------- | -------------------------------- | --------------------------------- | ---------------------------------------------- |
| `platform` (parent)     | always                           | `<release>-platform-sa`           | backend, cron, frontend Deployments            |
| `studios`               | `studios.enabled`                | `<release>-studios-sa`            | server StatefulSet, proxy Deployment           |
| `wave`                  | `wave.enabled`                   | `<release>-wave-sa`               | wave Deployment                                |
| `mcp`                   | `mcp.enabled`                    | `<release>-mcp-sa`                | mcp Deployment                                 |
| `agent-backend`         | `agent-backend.enabled`          | `<release>-agent-backend-sa`      | agent-backend Deployment                       |
| `portal-web`            | `portal-web.enabled`             | `<release>-portal-web-sa`         | portal-web Deployment                          |
| `pipeline-optimization` | `pipeline-optimization.enabled`  | `<release>-pipeline-optimization-sa` | pipeline-optimization Deployment            |

¹ Default name when `serviceAccount.name` is unset. See [How names are generated](#how-names-are-generated).

For a release named `tower` with every subchart enabled, the full set of created ServiceAccounts is:

```
tower-platform-sa
tower-studios-sa
tower-wave-sa
tower-mcp-sa
tower-agent-backend-sa
tower-portal-web-sa
tower-pipeline-optimization-sa
```

## How names are generated

Every chart uses the same helper (`<chart>.serviceAccountName`):

```gotemplate
{{- define "platform.serviceAccountName" -}}
{{- default (printf "%s-sa" (include "common.names.fullname" .)) .Values.serviceAccount.name -}}
{{- end -}}
```

The precedence is:

1. **`serviceAccount.name`** — if set, it is used verbatim as the ServiceAccount name.
2. Otherwise **`<common.names.fullname>-sa`**.

`common.names.fullname` (from the Bitnami common library) resolves to:

- `fullnameOverride` if set, else
- `<Release.Name>-<nameOverride | Chart.Name>`, collapsing to just `<Release.Name>` when the
  release name already contains the chart name.

Because the default incorporates `Release.Name`, **the generated names differ per release**, so
multiple releases can coexist in the same namespace without colliding. In a subchart, `Chart.Name`
is the subchart's own name (e.g. `studios`) while `Release.Name` is the shared parent release, which
is why each subchart gets its own distinct `<release>-<subchart>-sa`.

The same helper is used both to name the created ServiceAccount **and** to set `serviceAccountName`
on the chart's workloads, so the two always stay in sync.

## Controlling creation and naming

Two values drive the behaviour, and they are independent:

| Value                    | Default | Purpose                                                                 |
| ------------------------ | ------- | ----------------------------------------------------------------------- |
| `serviceAccount.create`  | `true`  | Whether this chart creates the ServiceAccount.                          |
| `serviceAccount.name`    | `""`    | The name to use (created and/or referenced). Generated when empty.      |

Behaviour matrix:

| `create` | `name`      | Result                                                                                |
| -------- | ----------- | ------------------------------------------------------------------------------------- |
| `true`   | `""`        | Chart creates `<release>-<chart>-sa`; workloads reference it. **(default)**           |
| `true`   | `my-sa`     | Chart creates a ServiceAccount named `my-sa`; workloads reference `my-sa`.            |
| `false`  | `""`        | Nothing created; workloads reference the namespace's `default` ServiceAccount.         |
| `false`  | `my-sa`     | Nothing created; workloads reference `my-sa` (must already exist / be managed elsewhere). |

> **Note:** when `create: false` and no `name` is given, workloads fall back to the namespace's
> built-in `default` ServiceAccount rather than a generated `<release>-<chart>-sa` name. This avoids
> referencing a ServiceAccount that nothing creates (which Kubernetes would reject at pod admission).
> Set `serviceAccount.name` if you want workloads to use a specific pre-existing ServiceAccount.

### Examples

Create the ServiceAccount with a custom name:

```yaml
serviceAccount:
  create: true
  name: platform-sa
```

Use an existing, externally-managed ServiceAccount (chart creates nothing):

```yaml
serviceAccount:
  create: false
  name: my-preexisting-sa
```

Each subchart has its own `serviceAccount` block, so overrides are scoped per component, e.g.:

```yaml
serviceAccount:            # parent (platform) ServiceAccount
  name: platform-sa

studios:
  serviceAccount:          # studios subchart ServiceAccount
    create: false
    name: shared-studios-sa
```

## Migration (breaking change)

Previously, setting `serviceAccount.name` **also suppressed** ServiceAccount creation — it was the
only way to point workloads at an existing ServiceAccount. Creation is now gated solely on
`serviceAccount.create` (default `true`).

If you set `serviceAccount.name` to reference an externally-managed ServiceAccount, add
`serviceAccount.create: false` (in the relevant chart / subchart block) so the chart does not try to
create it and conflict with the existing resource:

```yaml
serviceAccount:
  create: false           # add this line
  name: my-preexisting-sa
```

## Related settings

- **`serviceAccount.annotations`** — merged with `commonAnnotations` onto the created ServiceAccount.
  Commonly used for cloud IAM binding, e.g. IRSA (`eks.amazonaws.com/role-arn`) or GKE Workload
  Identity (`iam.gke.io/gcp-service-account`). Only applied when the chart creates the ServiceAccount.
- **`serviceAccount.automountServiceAccountToken`** — controls token automounting on the created
  ServiceAccount. Defaults vary by chart: `false` for `platform`, `portal-web`, and
  `pipeline-optimization`; `true` for `studios`, `mcp`, `wave`, and `agent-backend`.
- **`serviceAccount.imagePullSecretNames`** — extra image pull secrets attached to the ServiceAccount,
  in addition to any generated from `global.imageCredentials` and `global.imageCredentialsSecrets`.
