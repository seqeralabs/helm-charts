# High Availability Configuration

The example in this directory demonstrates how to configure the Seqera Platform for high
availability (HA) using multiple replicas, Pod Disruption Budgets (PDBs), pod anti-affinity, and
proper resource allocation.

## Overview

High availability ensures the Platform remains operational during:
- Node failures or maintenance
- Kubernetes cluster upgrades
- Unexpected pod crashes
- Rolling updates and deployments

## Quick Reference

| Component | HA Strategy | Configuration |
|-----------|-------------|---------------|
| **Backend** | Multiple replicas + PDB | `backend.extraOptionsSpec.replicas: 3` |
| **Frontend** | Multiple replicas + PDB | `frontend.extraOptionsSpec.replicas: 3` |
| **Cron** | Single replica (required) | `cron.extraOptionsSpec.replicas: 1` |
| **Pod Disruption Budgets** | Prevent simultaneous pod termination | `extraDeploy` with PDB resources |
| **Pod Anti-Affinity** | Spread pods across nodes/zones | `extraOptionsTemplateSpec.affinity` |

> [!IMPORTANT]
> **Cron Pod Cannot Be Replicated**: The cron component must run as a single replica because it:
> - Runs database migrations (backend waits for cron to be ready)
> - Handles asynchronous background tasks that must not be duplicated
> - Prevents race conditions in scheduled job execution

## Prerequisites

1. **Multiple Nodes**: Ensure your cluster has at least 3 nodes across different availability zones for proper distribution

   ```bash
   # Check node count and zones
   kubectl get nodes -L topology.kubernetes.io/zone
   ```

2. **External Dependencies**: MySQL and Redis must be highly available (managed services recommended):
   Refer to the [Seqera Platform Prerequisites](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common).

3. **Resource Capacity**: Ensure sufficient cluster resources for multiple replicas:

## High Availability Components

### 1. Multiple Replicas

Run multiple instances of backend and frontend pods to ensure availability during failures.

### 2. Pod Disruption Budgets (PDBs)

PDBs protect against simultaneous pod termination during:
- Node drains (for maintenance or upgrades)
- Cluster autoscaling
- Evictions due to resource pressure

**PDB Strategy**:
- `maxUnavailable: 1` - Only 1 pod can be down at a time (recommended for 3+ replicas)
- `minAvailable: 2` - Alternative: Always keep at least 2 pods running
- For frontend: Same configuration as backend
- For cron: **No PDB needed** (single replica)

### 3. Pod Anti-Affinity

Spread pods across different nodes and availability zones to prevent single points of failure.

**Key Points**:
- `topology.kubernetes.io/zone`: Spread across availability zones (primary) - you need to verify that your nodes are labeled correctly
- `kubernetes.io/hostname`: Spread across nodes (secondary)
- `preferredDuringScheduling`: Allows scheduling even if constraint can't be met
- Use `requiredDuringScheduling` for strict enforcement (ensure sufficient nodes are available)

### 4. Resource Requests and Limits

Proper resource allocation ensures:
- Pods have guaranteed resources
- Prevents resource starvation
- Enables proper scheduling decisions

**Best Practices**:
- Set memory limits equal to requests
- Don't set CPU limits (allow bursting)
- Monitor actual usage over time and adjust accordingly

### 5. Rolling Update Strategy

Configure how pods are replaced during updates.

**Recommendations**:
- `maxUnavailable: 1`: Ensures most replicas stay available during updates
- `maxSurge: 1`: Creates new pods before terminating old ones
- Works in conjunction with PDBs to maintain availability

### 6. Health Checks

Properly configured health checks ensure:
- Failed pods are restarted automatically
- Traffic is only sent to healthy pods
- Gradual rollout of new versions

## Complete Example

See [high-availability.yaml](high-availability.yaml) for a production-ready HA configuration. Some
required fields have been omitted for brevity.

## Verification

Verify pods are spread across nodes and zones:

```bash
# Check pod distribution
kubectl get pods \
  -l app.kubernetes.io/name=platform \
  -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,ZONE:.spec.nodeSelector

# Better view with node labels
kubectl get pods -o wide
```

## Troubleshooting

### Pods Not Spreading Across Zones

**Problem**: All pods scheduled on the same zone/node

**Solutions**:
1. Check if nodes have zone labels:
   ```bash
   kubectl get nodes --show-labels | grep topology.kubernetes.io/zone
   ```

2. Use `requiredDuringSchedulingIgnoredDuringExecution` for strict enforcement:
   ```yaml
   podAntiAffinity:
     requiredDuringSchedulingIgnoredDuringExecution:
       - labelSelector:
           matchLabels:
             app.kubernetes.io/component: backend
         topologyKey: topology.kubernetes.io/zone
   ```

3. Ensure you have enough nodes in different zones

### Pods Stuck in Pending

**Problem**: Insufficient resources or affinity rules too strict

**Solutions**:
1. Check pod events:
   ```bash
   kubectl describe pod <pod-name>
   ```

2. Relax anti-affinity from `required` to `preferred`

3. Increase cluster capacity or adjust resource requests

### PDB Blocks Node Drain

**Problem**: Cannot drain node due to PDB constraints

**Solutions**:
1. This is expected behavior - PDB is protecting your workload
2. Wait for other pods to become available
3. Temporarily increase replicas before draining:
   ```bash
   kubectl scale deployment platform-backend --replicas=4
   ```
4. Only override PDB if absolutely necessary:
   ```bash
   kubectl drain <node-name> --disable-eviction
   ```

### Database Connection Failures During Updates

**Problem**: Backend pods restart and database connections timeout

**Solutions**:
1. Increase `maxUnavailable` to allow more aggressive rollouts if you have sufficient replicas
2. Tune database connection pool settings
3. Ensure external MySQL and Redis have HA enabled

## Advanced Configurations

### Topology Spread Constraints

For more fine-grained control over pod distribution, use topology spread constraints.
See [pod-allocation-strategies](../pod-allocation-strategies/) for more details.

### Horizontal Pod Autoscaling (HPA)

Automatically scale based on CPU/memory usage. Refer to the commented section in the example YAML.
**Note**: HPA requires metrics-server installed in your cluster.

## Additional Resources

- [Kubernetes Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Pod Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
- [Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [AWS Multi-AZ RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [GCP Cloud SQL HA](https://cloud.google.com/sql/docs/mysql/high-availability)
