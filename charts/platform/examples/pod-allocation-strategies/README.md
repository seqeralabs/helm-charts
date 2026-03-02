# Allocating Platform pods

The `nodeSelector` property can be used to specify the nodes on which Platform pods must be
scheduled on based on node labels.

Pod affinity and anti-affinity help control the scheduling of pods based on the labels of other pods
in the cluster, which can be useful for improving availability, performance, and resource
utilization. Node affinity allows you to constrain which nodes your pods are eligible to be
scheduled on based on the labels of the nodes in your cluster. Refer to the [Kubernetes
documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/) for details
on pod affinity and anti-affinity rules and how to customize them based on your requirements.

Topology spread constraints help ensure that pods are evenly distributed across different topology
domains, such as availability zones or nodes, to improve availability and fault tolerance.

> [!IMPORTANT]
> **Cron Pod Limitation**: Only 1 replica of the Platform cron component is supported (it handles
> database migrations and prevents duplicate job execution). Pod affinity and anti-affinity rules on
> cron will have no effect. **Focus your HA strategies on the backend (supports multiple replicas)
> and frontend components instead.**

## Quick Reference

| Strategy | When to Use | Configuration Key |
|----------|-------------|-------------------|
| **Node Selector** | Target specific node types (SSD, GPU) | `extraOptionsTemplateSpec.nodeSelector` |
| **Node Affinity** | Complex node targeting with multiple conditions | `extraOptionsTemplateSpec.affinity.nodeAffinity` |
| **Pod Affinity** | Co-locate related services | `extraOptionsTemplateSpec.affinity.podAffinity` |
| **Pod Anti-Affinity** | Spread pods across nodes for HA | `extraOptionsTemplateSpec.affinity.podAntiAffinity` |
| **Topology Spread** | Balance pods across zones/nodes | `extraOptionsTemplateSpec.topologySpreadConstraints` |

**Applies to**: `backend.*`, `frontend.*`, and `cron.*` (though cron is single-replica).

## Prerequisites

Before configuring pod allocation strategies:

1. **Ensure multiple backend replicas** (default is 3):
   ```yaml
   backend:
     extraOptionsSpec:
       replicas: 3  # Anti-affinity requires multiple pods
   ```

2. **Check existing node labels** to use with node selectors:
   ```bash
   kubectl get nodes --show-labels
   ```

3. **Verify topology labels exist** for zone-based spreading:
   ```bash
   kubectl get nodes -L topology.kubernetes.io/zone
   ```

## Node Selector

Node selector allows you to specify key-value pairs that must match the labels on nodes for your
pods to be scheduled on those nodes. This is a simple way to ensure that certain workloads run on
specific types of nodes.
To set a node selector for one of the Platform components (backend, frontend, cron), set the
`backend.extraOptionsTemplateSpec.nodeSelector`, `frontend.extraOptionsTemplateSpec.nodeSelector`, or
`cron.extraOptionsTemplateSpec.nodeSelector` values in the Helm chart.
Here is an example of setting a node selector for the backend component to schedule it only on nodes
labeled with `disktype: ssd`:

```yaml
backend:
  extraOptionsTemplateSpec:
    nodeSelector:
      disktype: ssd
```

## Pod Affinity

Pod affinity allows you to specify that certain pods should be scheduled on nodes where other pods
with specific labels are already running. This can be useful for co-locating related services to
reduce latency.
To enable pod affinity for one of the Platform components (backend, frontend, cron), set the
`backend.extraOptionsTemplateSpec.affinity`, `frontend.extraOptionsTemplateSpec.affinity`, or
`cron.extraOptionsTemplateSpec.affinity` values in the Helm chart.

Here is an example of setting pod affinity for the backend component to co-locate it with other
pods labeled with `app.kubernetes.io/name: my-related-app`:

```yaml
backend:
  extraOptionsTemplateSpec:
    affinity:
      podAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - my-related-app
            topologyKey: "kubernetes.io/hostname"
```

Similarly, you can set pod affinity for the frontend and cron components by modifying their
`extraOptionsTemplateSpec.affinity` values.

## Node Affinity

Node affinity allows you to specify rules about which nodes your pods can be scheduled on based on
node labels. This can help ensure that certain workloads run on specific types of nodes.
To set node affinity for one of the Platform components (backend, frontend, cron), set the
`backend.extraOptionsTemplateSpec.affinity`, `frontend.extraOptionsTemplateSpec.affinity`, or
`cron.extraOptionsTemplateSpec.affinity` values in the Helm chart.
Here is an example of setting node affinity for the backend component to schedule it only on nodes
labeled with `disktype: ssd` or `disktype: nvme`:

```yaml
backend:
  extraOptionsTemplateSpec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: disktype
                  operator: In
                  values:
                    - ssd
                    - nvme
```

This is more flexible than using `nodeSelector`, as it allows you to specify multiple conditions for
node selection, and you can use different operators like `In`, `NotIn`, `Exists`, etc.

### Negative node Affinity

Node affinity also allows you to specify rules about which nodes your pods should avoid being
scheduled on based on node labels. This can help ensure that certain workloads do not run on
specific types of nodes.
To set node affinity for one of the Platform components (backend, frontend, cron), set the
`backend.extraOptionsTemplateSpec.affinity`, `frontend.extraOptionsTemplateSpec.affinity`, or
`cron.extraOptionsTemplateSpec.affinity` values in the Helm chart.

Here is an example of setting node affinity for the backend component to avoid scheduling
on spot/preemptible instances:

```yaml
backend:
  extraOptionsTemplateSpec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: node-lifecycle
                  operator: NotIn
                  values:
                    - spot
                    - preemptible
```

This ensures production workloads don't run on cost-optimized spot instances that can be terminated
at any time.

## Pod Anti-Affinity

Pod anti-affinity allows you to specify that certain pods should not be scheduled on nodes where
other pods with specific labels are running. This can help improve availability by spreading pods
across different nodes.
To enable pod anti-affinity for one of the Platform components (backend, frontend, cron), set the
`backend.extraOptionsTemplateSpec.affinity`, `frontend.extraOptionsTemplateSpec.affinity`, or
`cron.extraOptionsTemplateSpec.affinity` values in the Helm chart.
Here is an example of setting pod anti-affinity for the backend component to avoid co-locating it
with other backend pods, spreading them across different nodes to increase availability:

```yaml
backend:
  extraOptionsTemplateSpec:
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:  # Use "preferred" for flexibility
        - weight: 100  # Higher weight = stronger preference (1-100)
          podAffinityTerm:
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: platform
                app.kubernetes.io/component: backend
            topologyKey: kubernetes.io/hostname  # Spread across nodes
            # Use topology.kubernetes.io/zone to spread across availability zones
```

**Note**: Use `requiredDuringSchedulingIgnoredDuringExecution` for strict enforcement, but ensure you
have enough nodes to satisfy the constraint, otherwise pods will fail to schedule.

## Topology Spread Constraints

Topology spread constraints help ensure that pods are evenly distributed across different topology
domains, such as availability zones or nodes, to improve availability and fault tolerance. This is a
more advanced alternative to pod anti-affinity that provides finer-grained control over pod
distribution.

Here is an example of spreading backend pods across availability zones with a maximum skew of 1:

```yaml
backend:
  extraOptionsSpec:
    replicas: 3  # Ensure you have at least 3 replicas for multi-zone distribution
  extraOptionsTemplateSpec:
    topologySpreadConstraints:
      - maxSkew: 1  # Maximum difference in pod count between zones
        topologyKey: topology.kubernetes.io/zone  # Spread across zones
        whenUnsatisfiable: DoNotSchedule  # Strictly enforce the constraint
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: platform
            app.kubernetes.io/component: backend
```

**Note**: `maxSkew: 1` means the difference between zones won't exceed 1 pod. With 3 replicas across
3 zones, you'll get 1 pod per zone. Use `maxSkew: 2` for more flexibility.

To spread across nodes (instead of zones), use `topologyKey: kubernetes.io/hostname`.
Set `whenUnsatisfiable: ScheduleAnyway` if you want pods to schedule even when the constraint cannot
be satisfied (e.g., not enough zones available).

Refer to the [Kubernetes
documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/)
for more details on this feature and how to customize it further based on your requirements.
See also this [AWS
article](https://docs.aws.amazon.com/prescriptive-guidance/latest/ha-resiliency-amazon-eks-apps/spread-workloads.html)
for practical examples of using topology spread constraints with AWS Availability Zones.
