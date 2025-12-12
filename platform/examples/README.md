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

## Additional Resources

- [Seqera Platform Documentation](https://docs.seqera.io/)
- [Helm Chart Values Reference](../README.md)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
