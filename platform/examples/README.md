# Platform Deployment Examples

This directory contains practical examples demonstrating different deployment configurations for the Seqera Platform Helm chart. Each example focuses on a specific use case or deployment pattern.

## Available Examples

| Example | Description |
|---------|-------------|
| [high-availability/](high-availability/) | Production HA setup with multiple replicas, Pod Disruption Budgets, pod anti-affinity, and proper resource allocation |
| [ingress-configurations/](ingress-configurations/) | Various ingress controller setups (NGINX, AWS ALB, GKE, Traefik) with TLS certificate management |
| [kustomize/](kustomize/) | Using Kustomize for environment-specific configurations and overlays |
| [passwords-from-secrets/](passwords-from-secrets/) | Managing sensitive credentials using Kubernetes secrets |
| [pod-allocation-strategies/](pod-allocation-strategies/) | Node selectors, affinity rules, anti-affinity, and topology spread constraints |

The following examples demonstrate possible configurations for enabling and customizing specific subcharts within the Platform Helm chart:

| Example | Description |
|---------|-------------|
| [pipeline-optimization/](pipeline-optimization/) | Enabling and configuring the Pipeline
Optimization service subchart with database setup and registry access |

## Additional Resources

- [Seqera Platform Documentation](https://docs.seqera.io/)
- [Helm Chart Values Reference](../README.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
