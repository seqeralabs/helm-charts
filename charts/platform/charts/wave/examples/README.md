# wave Examples

## standalone.yaml

Minimal values for deploying the `wave` chart independently, without the parent `platform` chart.

### Ingress configuration

The example omits ingress details because the right configuration depends on your ingress
controller and cloud provider. See the
[ingress configurations guide](../../../examples/ingress-configurations/README.md)
for ready-to-use examples covering NGINX + cert-manager, AWS ALB, GKE managed certificates,
Traefik, wildcard TLS, and more.
