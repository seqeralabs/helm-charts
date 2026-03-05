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

## Disabling Pipeline Optimization

To disable the feature without uninstalling the entire Platform chart, set `pipeline-optimization.enabled=false` in your values file.

This will remove the Pipeline Optimization deployment but preserve the Platform installation.

## Additional Resources

- [Seqera Platform Pipeline Optimization Documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization)
- [Pipeline Optimization Subchart README](../../charts/pipeline-optimization/README.md)
- [Pipeline Optimization Subchart Values Reference](../../charts/pipeline-optimization/values.yaml)
- [Vendoring Container Images](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
