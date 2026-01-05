# Pipeline Optimization Configuration

The example in this directory demonstrates how to enable and configure the Seqera Pipeline Optimization service (formerly known as Groundswell) as a subchart within the Platform Helm chart.

## Overview

The Pipeline Optimization service analyzes pipeline execution data to provide intelligent resource recommendations, helping users optimize their Nextflow workflows for cost and performance. It requires:
- Its own dedicated MySQL database
- Read-only access to the Platform's main database
- Proper network connectivity between services

## Quick Reference

| Component | Configuration Path | Notes |
|-----------|-------------------|-------|
| **Enable Feature** | `pipeline-optimization.enabled: true` | Controls whether the subchart is deployed |
| **Service Database** | `pipeline-optimization.database.*` | Dedicated MySQL database for Pipeline Optimization |
| **Platform Database** | `pipeline-optimization.platformDatabase.*` | Read-only access to Platform data |
| **Container Images** | `pipeline-optimization.image.*` | Container registry and image configuration |
| **Service Port** | `pipeline-optimization.service.http.port` | Default: 8090 |

> [!IMPORTANT]
> **Two Separate Databases Required**: Pipeline Optimization requires two database connections:
> 1. **Service Database** (`.database.*`): A dedicated MySQL database for storing optimization data
> 2. **Platform Database** (`.platformDatabase.*`): Read-only access to the Platform's database to analyze pipeline data

## Prerequisites

1. **Seqera Platform Installed**: The Pipeline Optimization service is a subchart of the Platform
   chart, but can be used independently as long as Platform is installed and accessible.

2. **Two MySQL Databases**:
   - Platform database (existing)
   - Pipeline Optimization database (new, dedicated instance)

  Refer to the [Database Setup](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization) documentation for guidance.

3. **Container Registry Access**: Access to the Seqera container images:
   - Option A: Credentials for `cr.seqera.io`
   - Option B: Vendor images to your private registry

   See [Vendoring Seqera Container Images](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry)

4. **Kubernetes Resources**: Sufficient cluster capacity for the additional pod

## Complete Example

See [values.yaml](values.yaml) for a complete working configuration. Some Platform-specific required
fields (like ingress configuration) have been omitted for brevity.

## Troubleshooting

### Pod Not Starting

**Problem**: Pipeline Optimization pod is in `Pending` or `CrashLoopBackOff` state

**Solutions**:
1. Check pod events:
   ```bash
   kubectl describe pod -n your-namespace -l app.kubernetes.io/name=pipeline-optimization
   ```

2. Check logs:
   ```bash
   kubectl logs -n your-namespace -l app.kubernetes.io/name=pipeline-optimization
   ```

3. Verify database connectivity:
   ```bash
   # Test connection to Pipeline Optimization database
   kubectl run -it --rm mysql-test --image=mysql:9 --restart=Never -- \
     mysql -h mysql.example.com -u pipeline_opt_user -p pipeline_opt_db

   # Test connection to Platform database (read-only)
   kubectl run -it --rm mysql-test --image=mysql:9 --restart=Never -- \
     mysql -h mysql.example.com -u pipeline_opt_reader -p platform_db
   ```

### Database Migration Failures

**Problem**: Init container fails during database migration

**Solutions**:
1. Check init container logs:
   ```bash
   kubectl logs -n your-namespace -l app.kubernetes.io/name=pipeline-optimization \
     -c db-migration
   ```

2. Verify database user has sufficient privileges:
   ```sql
   -- User needs ALL privileges on the Pipeline Optimization database
   SHOW GRANTS FOR 'pipeline_opt_user'@'%';
   ```

3. Check if database schema exists:
   ```sql
   USE pipeline_opt_db;
   SHOW TABLES;
   ```

### Service Not Accessible

**Problem**: Cannot connect to Pipeline Optimization service from Platform

**Solutions**:
1. Verify service exists:
   ```bash
   kubectl get svc -n your-namespace platform-pipeline-optimization
   ```

2. Check service endpoints:
   ```bash
   kubectl get endpoints -n your-namespace platform-pipeline-optimization
   ```

3. Test service connectivity from within cluster:
   ```bash
   kubectl run -it --rm test-pod --image=curlimages/curl --restart=Never -- \
     curl -v http://platform-pipeline-optimization.your-namespace.svc.cluster.local:8090/api/v1/health
   ```

### Platform Not Detecting Pipeline Optimization

**Problem**: Platform UI doesn't show Pipeline Optimization features

**Solutions**:
1. Verify the service is registered in Platform configuration. Check Platform logs:

   ```bash
   kubectl logs -n your-namespace -l app.kubernetes.io/component=backend | grep -i groundswell
   ```

   There should be an entry indicating enabling the Pipeline Optimization ("Groundswell") service:
   `Enabling Groundswell service`.

## Disabling Pipeline Optimization

To disable the feature without uninstalling the entire Platform chart, set `pipeline-optimization.enabled=false` in your values file.

This will remove the Pipeline Optimization deployment but preserve the Platform installation.

## Additional Resources

- [Seqera Platform Pipeline Optimization Documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization)
- [Pipeline Optimization Subchart README](../../charts/pipeline-optimization/README.md)
- [Pipeline Optimization Subchart Values Reference](../../charts/pipeline-optimization/values.yaml)
- [Vendoring Container Images](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
