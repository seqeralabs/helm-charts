<!--
 Copyright (c) 2026 Seqera Labs
 All rights reserved.

 SPDX-License-Identifier: Apache-2.0
-->

# Resources

The Seqera charts don't define default resources for their workloads. This is because the resource
requirements of a given workload can vary widely depending on the deployment environment, the
expected load, and the specific use case.
Inside the `values.yaml` file, you can find `resources` section for each component, where you can
define CPU and memory requests and limits.
In general, we recommend not setting CPU limits as long as all applications define CPU requests, as
explained by [this article](https://home.robusta.dev/blog/stop-using-cpu-limits). CPU is a
compressible resource: when a node is under contention, a container over its request is throttled
rather than killed, so a CPU limit mostly caps performance without improving stability.

Memory, by contrast, is not compressible: a container that exceeds its memory limit is OOM-killed.
For this reason we recommend setting `requests.memory` equal to `limits.memory`, so a workload is
never scheduled with less memory than it may end up using. This is the pattern shown in the
commented `resources` examples in `values.yaml`:

```yaml
resources:
  requests:
    cpu: "1"
    memory: "4000Mi"
  limits:
    memory: "4000Mi"
```

Setting `requests.memory == limits.memory` (and omitting the CPU limit) places the pod in the
[Burstable](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/) QoS class. To reach the
`Guaranteed` class, set both CPU and memory requests equal to their limits for every container in
the pod.

The amounts in the `resources` blocks in the various `values.yaml` files are sensible starting
points, not tuned figures. Observe real CPU and memory usage under your expected load, for example
with metrics-server or Prometheus or simply with `kubectl top pod`, and adjust accordingly.
The [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
in recommendation mode can help estimate appropriate values.
