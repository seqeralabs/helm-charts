# Seqera Studios Configuration

This example demonstrates how to enable and configure Seqera Studios, which provides interactive data analysis environments (R-IDE, JupyterLab, VS Code, etc.) integrated with Seqera Platform.

## Overview

Studios allows users to launch interactive sessions for data analysis and visualization. Refer to
the docs for more details: https://docs.seqera.io/platform-enterprise/studios/overview

## Prerequisites

Before deploying Studios, ensure you have:

1. **Seqera Platform** already deployed and accessible (doesn't need to be deployed with the Helm chart)
2. A **Redis** cache for session storage: Seqera recommends a managed solution (AWS ElastiCache, GCP Memorystore, etc)
3. **DNS wildcard subdomain** configured (e.g., `*.studios.example.com`)

Studios uses OIDC tokens to securely register clients with Seqera Platform. Ensure your Platform
deployment has OIDC enabled (automatic if deployed via Helm): if no OIDC token is provided, the
chart will automatically create a random string token and configure it with Platform accordingly.

## DNS Configuration

Studios requires wildcard DNS records pointing to your ingress controller/load balancer:

```
*.studios.example.com  ->  Your Ingress/LoadBalancer IP/hostname
```

Verify DNS resolution:

```bash
# Should resolve to your ingress IP
nslookup test.studios.example.com
```
