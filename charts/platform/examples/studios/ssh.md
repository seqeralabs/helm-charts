# Configure SSH access to Seqera Studios

Studios can accept direct SSH connections through the Studios proxy. Enabling this involves the
Platform backend (which advertises the SSH endpoint to users), the Studios proxy (which listens for
SSH), and a Layer-4 (TCP) path that exposes the proxy.

For how the feature works and its requirements, see [Seqera Studios SSH
configuration](https://docs.seqera.io/platform-enterprise/enterprise/studios-ssh). This page only
covers the chart-specific configuration.

> SSH support is a public-preview feature. Confirm that the Platform and Studios versions in use
> support it before enabling it in production.

## Platform backend configuration

The Platform chart does not have dedicated values for the SSH endpoint variables. Add them to
`backend.extraEnvVars`:

```yaml
backend:
  extraEnvVars:
    - name: TOWER_SSH_KEYS_MANAGEMENT_ENABLED
      value: "true"
    - name: TOWER_DATA_STUDIO_SSH_ALLOWED_WORKSPACES
      value: "" # Enable for all workspaces; use comma-separated workspace IDs to restrict it
    - name: TOWER_DATA_STUDIO_CONNECT_SSH_PORT
      value: "2222"
    - name: TOWER_DATA_STUDIO_CONNECT_SSH_KEY_FINGERPRINT
      valueFrom:
        secretKeyRef:
          name: studios-ssh-keys
          key: connect_proxy_fingerprint
    - name: TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS
      value: ssh.example.com
```

`TOWER_DATA_STUDIO_CONNECT_SSH_PORT` is the client-facing port advertised to users, so it must match
the externally reachable TCP listener, accounting for any port translation. If the load balancer maps
public port `5555` to proxy port `2222`, set this to `5555`.

## Studios proxy configuration

Enable the SSH listener on the proxy and mount the private and public key files:

```yaml
studios:
  proxy:
    extraEnvVars:
      - name: CONNECT_SSH_ENABLED
        value: "true"
      - name: CONNECT_SSH_ADDR
        value: ":2222"
      - name: CONNECT_SSH_KEY_PATH
        value: /etc/connect/ssh-keys/connect_proxy

    extraVolumes:
      - name: ssh-keys
        secret:
          secretName: studios-ssh-keys
          defaultMode: 0400

    extraVolumeMounts:
      - name: ssh-keys
        mountPath: /etc/connect/ssh-keys
        readOnly: true
```

The mounted Secret is expected to contain `connect_proxy`, `connect_proxy.pub`, and
`connect_proxy_fingerprint`. All proxy replicas must use the same key pair. Do not place private key
material in a values file; create the Secret separately or synchronize it from an external secret
manager.

## Exposing the proxy over TCP

The Studios subchart creates an HTTP proxy Service and a headless server Service, but no dedicated
SSH Service or NLB. Use `studios.extraDeploy` to add the Layer-4 resources for your infrastructure
model. A dedicated Service (separate from the proxy's HTTP Service) is recommended so SSH and
HTTP/HTTPS traffic stay independent.

The selector in the examples below matches the labels emitted by the Studios proxy Deployment. If
`studios.proxy.podLabels` changes `app.kubernetes.io/name`, update the selector to match.

The examples below are AWS-specific (NLB and the AWS Load Balancer Controller). Other providers need
an equivalent Layer-4 setup using their own load balancer resources and annotations.

### Existing NLB managed outside Helm

When Terraform or another tool manages the NLB and target groups, Helm can manage a dedicated
NodePort Service and the AWS Load Balancer Controller `TargetGroupBinding`:

```yaml
studios:
  extraDeploy:
    - apiVersion: v1
      kind: Service
      metadata:
        name: '{{ printf "%s-studios-proxy-ssh" .Release.Name }}'
      spec:
        type: NodePort
        ports:
          - name: ssh
            port: 5555
            targetPort: 2222
            protocol: TCP
            nodePort: 30555
        selector:
          app.kubernetes.io/instance: '{{ .Release.Name }}'
          app.kubernetes.io/name: studios
          app.kubernetes.io/component: proxy

    - apiVersion: elbv2.k8s.aws/v1beta1
      kind: TargetGroupBinding
      metadata:
        name: '{{ printf "%s-studios-proxy-ssh" .Release.Name }}'
      spec:
        serviceRef:
          name: '{{ printf "%s-studios-proxy-ssh" .Release.Name }}'
          port: 5555
        targetType: instance
        targetGroupName: replace-with-target-group-name
```

`TargetGroupBinding` requires the AWS Load Balancer Controller and its CRDs.

### NLB managed by Kubernetes

If the AWS Load Balancer Controller should provision and own the NLB, deploy a dedicated
`LoadBalancer` Service:

```yaml
studios:
  extraDeploy:
    - apiVersion: v1
      kind: Service
      metadata:
        name: '{{ printf "%s-studios-proxy-ssh" .Release.Name }}'
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      spec:
        type: LoadBalancer
        loadBalancerClass: service.k8s.aws/nlb
        ports:
          - name: ssh
            port: 2222
            targetPort: 2222
            protocol: TCP
        selector:
          app.kubernetes.io/instance: '{{ .Release.Name }}'
          app.kubernetes.io/name: studios
          app.kubernetes.io/component: proxy
        # Restrict this to the networks that require SSH access.
        loadBalancerSourceRanges:
          - 203.0.113.0/24
```

After the NLB is created, point the SSH DNS name at its hostname and set
`TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS` to that DNS name.

### Adding SSH to the existing proxy Service

Adding a port to the existing proxy Service is also supported, and can be useful when an externally
managed NLB targets only that additional NodePort:

```yaml
studios:
  proxy:
    service:
      type: NodePort
      extraServices:
        - name: ssh
          port: 2222
          targetPort: 2222
          protocol: TCP
          nodePort: 30222
```

This couples HTTP and SSH to one Service, so prefer a dedicated Service via `studios.extraDeploy`
unless that trade-off is intentional. Annotations for the existing proxy Service go under
`studios.proxy.serviceAnnotations` (`studios.proxy.service.extraOptions` writes only to the Service
`spec`, not metadata).

## References

- [Seqera Studios SSH configuration](https://docs.seqera.io/platform-enterprise/enterprise/studios-ssh)
- [Seqera Platform configuration reference](https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview)
- [AWS Load Balancer Controller: Network Load Balancer](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/service/nlb/)
- [AWS Load Balancer Controller: TargetGroupBinding](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/targetgroupbinding/targetgroupbinding/)
