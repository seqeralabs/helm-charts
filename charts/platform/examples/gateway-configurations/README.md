# Gateway API Configurations

This directory contains examples of routing the Seqera Platform through the
[Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) instead of Ingress. The Gateway API is
the successor to Ingress and is supported by an increasing number of controllers (NGINX Gateway
Fabric, Envoy Gateway, Istio, Cilium, Traefik, cloud provider implementations, …).

The charts render **`HTTPRoute`** objects only. They attach to a **`Gateway` that you manage
outside this chart** via `httpRoute.parentRefs`. The chart never creates the `Gateway` or
`GatewayClass` — those are typically owned by the platform/cluster team, and TLS is terminated on
the Gateway listener rather than on the `HTTPRoute`.

`httpRoute.enabled` and `ingress.enabled` are independent switches. Enable whichever your cluster
uses (or both during a migration).

## Quick Reference

| Example | Controller | Use Case |
|---------|------------|----------|
| [nginx-gateway-fabric.yaml](#nginx-gateway-fabric) | NGINX Gateway Fabric | Attach HTTPRoutes to a shared Gateway with TLS on the listener |
| [envoy-gateway.yaml](#envoy-gateway) | Envoy Gateway | Cluster-wide `global.httpRoute` defaults across all subcharts |

## Prerequisites

1. **Install the Gateway API CRDs** (if your controller does not bundle them):
   ```bash
   kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 \
     || kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
   ```

2. **Install a Gateway controller** and create a `GatewayClass`:
   ```bash
   kubectl get gatewayclass
   ```

3. **Create the `Gateway`** the HTTPRoutes will attach to. This is what `httpRoute.parentRefs`
   points at. Example with TLS terminated on the listener:
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: seqera-gateway
     namespace: gateway-system
   spec:
     gatewayClassName: nginx        # or "eg" for Envoy Gateway, etc.
     listeners:
       - name: https
         protocol: HTTPS
         port: 443
         hostname: "*.example.com"
         tls:
           mode: Terminate
           certificateRefs:
             - kind: Secret
               name: seqera-wildcard-tls
         allowedRoutes:
           namespaces:
             from: All
   ```

4. **Configure DNS** to point your hostnames at the Gateway's external address:
   ```bash
   kubectl get gateway seqera-gateway -n gateway-system \
     -o jsonpath='{.status.addresses[*].value}'
   ```

## Examples

### NGINX Gateway Fabric

[nginx-gateway-fabric.yaml](nginx-gateway-fabric.yaml) attaches the platform HTTPRoute (and the
content-domain route) to a pre-existing `seqera-gateway` in the `gateway-system` namespace, using
its `https` listener.

### Envoy Gateway

[envoy-gateway.yaml](envoy-gateway.yaml) sets `global.httpRoute` defaults once so that the parent
chart and every enabled subchart (studios, wave, mcp, …) attach to the same shared Gateway without
repeating `parentRefs` per chart.

## How it maps to Ingress

| Ingress | Gateway API (this chart) |
|---------|--------------------------|
| `ingress.enabled` | `httpRoute.enabled` |
| `ingress.ingressClassName` | (n/a — selected by the Gateway's `gatewayClassName`) |
| `ingress.path` | `httpRoute.path` |
| `ingress.defaultPathType` (`Prefix`/`Exact`) | `httpRoute.matchType` (`PathPrefix`/`Exact`/`RegularExpression`) |
| `ingress.tls` | (n/a — TLS is configured on the Gateway listener) |
| `ingress.extraHosts` | `httpRoute.extraHosts` (each host becomes its own `HTTPRoute`) |
| — | `httpRoute.parentRefs` (the Gateway to attach to) |

## Troubleshooting

- **HTTPRoute not accepted / no address**: check the route status —
  `kubectl describe httproute <release>-platform`. A `ResolvedRefs`/`Accepted: False` condition
  usually means the `parentRefs` name/namespace/`sectionName` does not match a real Gateway
  listener, or the Gateway's `allowedRoutes` does not permit routes from your namespace.
- **404 from the Gateway**: confirm the request `Host` matches `spec.hostnames` on the rendered
  HTTPRoute (`kubectl get httproute <name> -o yaml`).
