<!--
 Copyright (c) 2025 - 2026 Seqera Labs
 All rights reserved.

 SPDX-License-Identifier: Apache-2.0
-->

# Deployment Sizing

This guide explains how much CPU and memory a Kubernetes cluster needs to run Seqera Platform with
the chart's **base install defaults**. Use it to size worker nodes before installing, and as a
starting point for capacity planning.

> **TL;DR** — A default install (all default-enabled components, Seqera's recommended per-pod
> requests) needs roughly **6 vCPU and 20 GiB of RAM** of schedulable capacity for the Platform
> pods themselves. Plan for at least **8 vCPU and 24–32 GiB of allocatable capacity** across your
> worker nodes to leave headroom for the OS, kubelet, system pods, and rolling updates.

## Important: the base chart sets almost no resource requests

The three core deployments (**backend**, **cron**, **frontend**) and most subcharts ship with
`resources: {}` — meaning **no CPU/memory requests or limits are set by default**. Out of the box
those pods run as `BestEffort`, so the scheduler reserves nothing for them and Kubernetes cannot
guarantee capacity or protect them under node pressure.

For that reason, **capacity planning must be based on the recommended requests**, not the literal
defaults. Seqera publishes sensible starting values as commented blocks next to every
`resources: {}` in `values.yaml`. The tables below use those recommended values — apply them in
production so pods are `Burstable`/`Guaranteed` and the scheduler can place them reliably.

**External prerequisites (not sized here):** the chart expects **MySQL** and **Redis** to be
provided externally (e.g. Amazon RDS + ElastiCache, or self-managed). Size those separately per
your database provider's guidance.

## Components deployed by a default install

| Component               | Kind        | Enabled by default | Replicas | Notes                                   |
| ----------------------- | ----------- | :----------------: | :------: | --------------------------------------- |
| backend                 | Deployment  |         ✅         |    3     | REST API / business logic               |
| cron                    | Deployment  |         ✅         |    1     | Single replica, `Recreate`, DB migrations |
| frontend                | Deployment  |         ✅         |    1     | Web UI                                  |
| studios – proxy         | Deployment  |         ✅         |    2     | Studios subchart                        |
| studios – server        | StatefulSet |         ✅         |    2     | Studios subchart                        |
| pipeline-optimization   | Deployment  |         ✅         |    1     |                                         |
| mcp                     | Deployment  |         ✅         |    1     | Model Context Protocol service          |
| agent-backend           | Deployment  |         ✅         |    1     | Used by the Seqera CLI `ai` command     |
| portal-web              | Deployment  |         ✅         |    1     | Ships real defaults (100m / 500Mi)      |
| wave                    | Deployment  |         ❌         |    –     | **Disabled** by default                 |

## Recommended per-pod requests (base install)

These are Seqera's recommended starting values. Memory `limit` equals memory `request` for each
component (CPU is left unlimited so pods can burst).

| Component             | Replicas | CPU request (each) | Mem request (each) | Mem limit (each) |
| --------------------- | :------: | :----------------: | :----------------: | :--------------: |
| backend               |    3     |        1000m       |      4000Mi        |     4000Mi       |
| cron                  |    1     |        1000m       |      4000Mi        |     4000Mi       |
| frontend              |    1     |         200m       |       200Mi        |      200Mi       |
| studios – proxy       |    2     |          30m       |        64Mi        |       64Mi       |
| studios – server      |    2     |          20m       |        50Mi        |       50Mi       |
| pipeline-optimization |    1     |        1000m       |      1000Mi        |     1000Mi       |
| mcp                   |    1     |         100m       |      1000Mi        |     1000Mi       |
| agent-backend         |    1     |         100m       |      1000Mi        |     1000Mi       |
| portal-web¹           |    1     |         100m       |       500Mi        |      500Mi       |

¹ `portal-web` is the only component whose defaults are set in the chart already; the rest come
from the recommended (commented) blocks in `values.yaml`.

## Totals for a default install

Summing `replicas × request` across all default-enabled components:

| Resource        | Total requested | Rounded |
| --------------- | :-------------: | :-----: |
| **CPU**         |   5.66 vCPU     | ~6 vCPU |
| **Memory**      |  ~19,928 Mi     | ~20 GiB |
| **Memory (limits)** | ~19,928 Mi  | ~20 GiB |

<details>
<summary>How the totals are calculated</summary>

**CPU:** `backend 3×1` + `cron 1×1` + `frontend 1×0.2` + `studios-proxy 2×0.03` +
`studios-server 2×0.02` + `pipeline-optimization 1×1` + `mcp 1×0.1` + `agent-backend 1×0.1` +
`portal-web 1×0.1` = **5.66 vCPU**

**Memory:** `backend 3×4000` + `cron 1×4000` + `frontend 1×200` + `studios-proxy 2×64` +
`studios-server 2×50` + `pipeline-optimization 1000` + `mcp 1000` + `agent-backend 1000` +
`portal-web 500` = **19,928 Mi (~20 GiB)**

</details>

The single biggest driver is the **backend at 3 replicas × 4 GiB = 12 GiB** — it dominates the
memory footprint. `cron` and `pipeline-optimization` are the next largest.

## Cluster capacity recommendation

Requests are what the scheduler must be able to place; they are **not** the whole story for node
sizing. Add headroom for the node OS + kubelet (~10–15%), DaemonSets/system pods, and the extra
capacity a `RollingUpdate` needs (surge replicas) during upgrades.

| Environment                         | Suggested schedulable capacity | Example node layout            |
| ----------------------------------- | ------------------------------ | ------------------------------ |
| **Production (base defaults)**      | ≥ 8 vCPU, 24–32 GiB RAM        | 3 × (4 vCPU / 16 GiB) nodes    |
| **Small / staging / evaluation**    | ≥ 4 vCPU, 12–16 GiB RAM        | 2 × (4 vCPU / 8 GiB) nodes     |

Spreading across **at least 3 nodes** lets the 3 backend replicas land on separate nodes for high
availability and survive a single-node failure. A single large node also works for non-HA setups
but concentrates risk.

## Reducing the footprint

For small, staging, or evaluation deployments you can trim resources significantly:

- **Scale the backend down** — the default 3 replicas exist for HA; set `backend.extraOptionsSpec.replicas: 1`
  to save 8 GiB of memory (`-2 × 4 GiB`).
- **Disable optional subcharts** you don't need. Each of the following is `enabled: true` by
  default and can be turned off:
  - `studios.enabled: false`
  - `pipeline-optimization.enabled: false` (frees ~1 vCPU / 1 GiB)
  - `mcp.enabled: false` (frees ~1 GiB)
  - `agent-backend.enabled: false` (frees ~1 GiB)
  - `portal-web.enabled: false` (frees 500Mi)

A minimal single-replica backend with optional subcharts disabled brings the core footprint down to
roughly **2.2 vCPU / 8 GiB** (backend + cron + frontend).

## Increasing the footprint

- **Wave** is disabled by default. If you enable it (`wave.enabled: true`), add its recommended
  request of **200m CPU / 1400Mi memory** per replica.
- **Scale for load** by raising `replicas` on `backend`, `frontend`, and the Studios components as
  concurrency grows. Multiply the per-pod request by your target replica count.

## How to apply resource requests

Set the recommended values under each component's `resources` key. For example, for the backend:

```yaml
backend:
  resources:
    requests:
      cpu: "1"
      memory: "4000Mi"
    limits:
      memory: "4000Mi"
```

The same pattern applies to `cron.resources`, `frontend.resources`, and each subchart's
`resources` block. Refer to the commented `resources:` examples in
[`values.yaml`](../values.yaml) for each component's recommended starting point.

## A note on init containers

Backend and cron pods run short-lived **init containers** (`waitForMySQL`, `waitForRedis`,
`waitForCron`), each requesting 500m CPU / 50Mi. These run sequentially and only at startup, so they
do **not** add to steady-state usage. Kubernetes schedules a pod on `max(largest init container,
sum of app containers)`, and the app containers dominate — so init containers do not increase the
capacity you need to plan for.
