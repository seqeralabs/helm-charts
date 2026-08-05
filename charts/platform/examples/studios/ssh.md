# Configure SSH access to Seqera Studios

Studios SSH requires configuration in three places:

1. The Platform backend tells users which SSH endpoint to connect to.
2. The Studios proxy listens for SSH and uses a dedicated key pair to authenticate to Studios.
3. The infrastructure exposes the proxy over Layer 4 (TCP).

The recommended network design is a dedicated TCP service and endpoint for SSH. This keeps SSH
traffic separate from the HTTP/HTTPS service used by the Studios ingress. The load balancer itself
can be managed by Helm, Terraform, or another infrastructure tool.

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

The variables have the following roles:

| Variable | Purpose |
| --- | --- |
| `TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS` | Client-facing SSH hostname. Omit it when SSH uses the same hostname as `TOWER_DATA_STUDIO_CONNECT_URL`; Platform falls back to the regular Connect URL. Set it when SSH has a dedicated hostname, such as an NLB endpoint. Supply a hostname, not a URL. |
| `TOWER_DATA_STUDIO_CONNECT_SSH_PORT` | Client-facing port displayed in SSH connection details. It must match the externally reachable TCP listener. If an NLB maps port `5555` to proxy port `2222`, set this to `5555`. The default is `22`. |
| `TOWER_DATA_STUDIO_CONNECT_SSH_KEY_FINGERPRINT` | Fingerprint of the proxy's SSH public key. Configuring it is recommended in production so that Studios only accept proxy-authenticated connections. |

Omit `TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS` entirely when a separate address is unnecessary. An
empty value is not needed to activate the fallback.

The fingerprint is not a private key. It can be stored as a normal Secret value while the private
key remains in the same Secret or is synchronized from an external secret manager. Generate the
fingerprint with `ssh-keygen -lf <public-key-file>` and store the `SHA256:...` value.

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

The Secret mounted above is expected to contain these keys:

```text
connect_proxy
connect_proxy.pub
connect_proxy_fingerprint
```

All proxy replicas must use the same key pair. Do not place private key material directly in a
values file. Create the Secret separately or synchronize it from an external secret manager.

## Recommended: a dedicated SSH Service

The Studios subchart creates an HTTP proxy Service and a headless server Service. It does not
create a dedicated SSH Service or NLB. Use `studios.extraDeploy` to add the resources needed by the
chosen infrastructure model.

A separate Service is preferred because it:

- exposes only the SSH port on the Layer-4 endpoint;
- leaves the proxy's HTTP Service and ingress behavior unchanged;
- permits independent annotations, source ranges, health checks, and lifecycle management; and
- makes the public SSH port, target port, and optional fixed NodePort explicit.

The selector in the following examples matches the labels emitted by the Studios proxy Deployment.
If `studios.proxy.podLabels` changes `app.kubernetes.io/name`, update the selector to match.

### Existing NLB managed outside Helm

When Terraform or another tool manages the NLB and target groups, Helm can manage a dedicated
NodePort Service and the AWS Load Balancer Controller `TargetGroupBinding`:

```yaml
backend:
  extraEnvVars:
    - name: TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS
      value: ssh.example.com
    - name: TOWER_DATA_STUDIO_CONNECT_SSH_PORT
      value: "5555"
    # Include the enablement and fingerprint variables shown earlier.

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

In this example the traffic path is:

```text
ssh.example.com:5555 -> NLB listener:5555 -> NodePort:30555 -> proxy:2222
```

The NLB target group port and its firewall rules must therefore use `30555`, while Platform must
advertise client-facing port `5555`. If both an internal and external NLB use the same Service, add
a second `TargetGroupBinding` with a unique Kubernetes name and the other target group.

`TargetGroupBinding` requires the AWS Load Balancer Controller and its CRDs. Restrict permission to
create these resources in multi-tenant clusters because a binding can reference existing target
groups.

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

Use `internal` instead of `internet-facing` when clients reach the endpoint through private
networking. The AWS controller uses NodePorts for `instance` targets. An `ip` target can instead
route directly to pod IPs when the cluster network supports native AWS VPC pod networking.

After the NLB is created, point the SSH DNS name at its hostname and set
`TOWER_DATA_STUDIO_CONNECT_SSH_ADDRESS` to that DNS name.

## Why not add SSH to the existing proxy Service?

Adding a port to the existing Service is supported:

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

This can be useful when an externally managed NLB targets only that additional NodePort. However,
it couples HTTP and SSH to one Kubernetes Service. Changing the Service to `LoadBalancer` for NLB
provisioning also places both its HTTP and SSH ports on the NLB, which conflicts with the preferred
separation of Layer-7 HTTPS and Layer-4 SSH traffic.

If annotations are added to the existing proxy Service, put them under
`studios.proxy.serviceAnnotations`. `studios.proxy.service.extraOptions` writes fields under the
Service `spec`; it cannot add metadata annotations.

For these reasons, use a dedicated Service through `studios.extraDeploy` unless the shared-Service
trade-off is intentional.

## Validation checklist

- The backend has SSH key management and the intended workspace allowlist enabled.
- The advertised SSH address resolves to the Layer-4 endpoint.
- The advertised SSH port is the client-facing listener port, including any port translation.
- The proxy listens on the Service `targetPort`.
- The mounted private key corresponds to the fingerprint configured on the backend.
- The SSH Service selector matches the Studios proxy pods.
- NLB listeners, target groups, NodePorts, security groups, and network ACLs agree on their ports.
- Source ranges and firewall rules limit SSH access to the required networks.
- HTTP access to Studios continues through its existing ingress and proxy Service.

## References

- [Seqera Studios SSH configuration](https://docs.seqera.io/platform-enterprise/enterprise/studios-ssh)
- [Seqera Platform configuration reference](https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview)
- [AWS Load Balancer Controller: Network Load Balancer](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/service/nlb/)
- [AWS Load Balancer Controller: TargetGroupBinding](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/targetgroupbinding/targetgroupbinding/)
