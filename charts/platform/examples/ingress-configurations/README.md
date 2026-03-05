# Ingress Configurations

This directory contains examples of different ingress configurations for the Seqera Platform. The ingress configuration varies significantly depending on your Kubernetes cluster setup, cloud provider, and ingress controller.

## Quick Reference

| Example | Ingress Controller | Use Case |
|---------|-------------------|----------|
| [nginx-cert-manager.yaml](#nginx-with-cert-manager) | NGINX | TLS with automatic certificate management |
| [aws-alb.yaml](#aws-application-load-balancer) | AWS ALB | AWS EKS with Application Load Balancer |
| [gke-managed-cert.yaml](#gke-with-google-managed-certificates) | GKE | Google Kubernetes Engine with managed certificates |
| [traefik.yaml](#traefik) | Traefik | Traefik ingress controller |
| [wildcard-tls.yaml](#wildcard-certificate) | Any | Single wildcard certificate for all domains |
| [extra-hosts.yaml](#multiple-hostnames) | Any | Multiple custom hostnames (API subdomain, etc.) |

## Prerequisites

1. **Ingress controller must be installed** in your cluster:
   ```bash
   # Check if an ingress controller is running
   kubectl get pods -A | grep -E 'ingress|alb'
   ```

2. **Configure DNS** to point to your ingress controller:
   ```bash
   # Get the ingress controller's external IP or hostname
   kubectl get svc -n ingress-nginx  # For NGINX
   # or
   kubectl get ingress -n <namespace>  # Check EXTERNAL-IP/ADDRESS
   ```

3. **For TLS**: Ensure you have certificates available or cert-manager installed:
   ```bash
   kubectl get pods -n cert-manager  # If using cert-manager
   ```

## Examples

### NGINX with cert-manager

**File**: [nginx-cert-manager.yaml](nginx-cert-manager.yaml)

**Use Case**: Most common production setup with automatic TLS certificate management via Let's Encrypt.

**Key Features**:
- NGINX ingress controller with standard annotations
- Automatic TLS certificate provisioning via cert-manager
- Separate certificates for main domain and content domain

**Prerequisites**:
- NGINX ingress controller installed
- cert-manager installed with ClusterIssuer configured

**DNS Requirements**:
- `platform.example.com` → Ingress external IP
- `user-data.example.com` → Same ingress external IP

### AWS Application Load Balancer

**File**: [aws-alb.yaml](aws-alb.yaml)

**Use Case**: AWS EKS clusters using the AWS Load Balancer Controller.

**Key Features**:
- Uses `/*` paths (required by ALB)
- Service type must be `NodePort`
- ALB-specific annotations for SSL, health checks, and listener rules
- Can use ACM certificates

**Prerequisites**:
- AWS Load Balancer Controller installed
- Service account with IAM role (IRSA) configured
- ACM certificate ARN or cert-manager with AWS support

**Important**: ALB ingress controller requires special path syntax and service configuration.

### GKE with Google-Managed Certificates

**File**: [gke-managed-cert.yaml](gke-managed-cert.yaml)

**Use Case**: Google Kubernetes Engine with automatic SSL certificate provisioning.

**Key Features**:
- Google-managed certificates (automatically provisioned and renewed)
- GKE ingress with HTTP(S) Load Balancing
- FrontendConfig and BackendConfig for advanced settings
- Optional Cloud Armor for DDoS protection

**Prerequisites**:
- GKE cluster with HTTP(S) Load Balancing enabled
- Domain ownership verified in Google Cloud Console
- DNS records pointing to GKE ingress IP

**Important**: Certificate provisioning can take 10-60 minutes. Check status with:
```bash
kubectl describe managedcertificate platform-managed-cert -n <namespace>
```

### Traefik

**File**: [traefik.yaml](traefik.yaml)

**Use Case**: Clusters using Traefik as the ingress controller.

**Key Features**:
- Traefik-specific annotations
- IngressRoute custom resource (optional)
- Middleware configuration for headers and redirects

**Prerequisites**:
- Traefik ingress controller installed

### Wildcard Certificate

**File**: [wildcard-tls.yaml](wildcard-tls.yaml)

**Use Case**: Using a single wildcard certificate for all Platform domains.

**Key Features**:
- Single TLS secret for `*.example.com`
- Covers main domain and content domain
- Simpler certificate management

**Prerequisites**:
- Wildcard certificate available (e.g., `*.example.com`)
- Certificate stored as Kubernetes secret

**Create wildcard certificate secret**:
```bash
kubectl create secret tls wildcard-tls \
  --cert=wildcard.crt \
  --key=wildcard.key \
  -n <namespace>
```

### Multiple Hostnames

**File**: [extra-hosts.yaml](extra-hosts.yaml)

**Use Case**: Exposing Platform on multiple custom hostnames (e.g., separate API subdomain).

**Key Features**:
- Main domain for frontend
- API subdomain for backend
- Content domain for user data
- Custom domain routing

**DNS Requirements**:
- `platform.example.com` → Ingress
- `api.platform.example.com` → Same ingress
- `user-data.example.com` → Same ingress

## Common Configuration Options

### Content Domain Separation

The Platform supports a separate content domain (`user-data.example.com`) to prevent XSS attacks by serving user-generated content from a different origin:

```yaml
global:
  platformExternalDomain: platform.example.com
  contentDomain: user-data.platform.example.com  # Or use custom domain
```

Set `contentDomain: ""` to disable this feature and serve content from the main domain.

### TLS Configuration

**Separate certificates per domain**:
```yaml
ingress:
  tls:
    - hosts:
        - platform.example.com
      secretName: platform-tls
    - hosts:
        - user-data.example.com
      secretName: content-tls
```

**Wildcard certificate**:
```yaml
ingress:
  tls:
    - hosts:
        - platform.example.com
        - user-data.example.com
      secretName: wildcard-tls
```

### Path Types

- `ImplementationSpecific` (default): Ingress controller decides interpretation
- `Prefix`: Matches URL path prefix
- `Exact`: Exact path match only

For AWS ALB, always use path `/*` and `Prefix` type.

### Common Annotations

**NGINX**:
```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/proxy-body-size: "500m"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
  nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

**cert-manager**:
```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
  cert-manager.io/acme-challenge-type: "http01"
```

**AWS ALB**:
```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip  # or instance
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
  alb.ingress.kubernetes.io/ssl-redirect: '443'
```

## Verifying Your Ingress

After deploying, verify the ingress is configured correctly:

**Check ingress resource**:
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
```

**Check ingress controller logs**:
```bash
# For NGINX
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# For AWS ALB
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Test DNS resolution**:
```bash
nslookup platform.example.com
nslookup user-data.example.com
```

**Test TLS certificate**:
```bash
curl -v https://platform.example.com
openssl s_client -connect platform.example.com:443 -servername platform.example.com
```

**Check certificate expiry** (if using cert-manager):
```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <cert-name> -n <namespace>
```

## Troubleshooting

### Ingress shows no ADDRESS/External IP
- Check if ingress controller is running
- Verify service type (LoadBalancer or NodePort)
- For cloud providers, check service annotations

### TLS certificate not provisioned
- Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
- Verify ClusterIssuer exists: `kubectl get clusterissuer`
- Check Certificate resource: `kubectl describe certificate -n <namespace>`
- Ensure HTTP01 challenge can reach ingress (port 80 must be accessible)

### 502 Bad Gateway / Backend not reachable
- Verify backend service is running: `kubectl get pods -n <namespace>`
- Check service endpoints: `kubectl get endpoints -n <namespace>`
- Review ingress controller logs for backend connection errors

### AWS ALB not created
- Check AWS Load Balancer Controller logs
- Verify IAM permissions (IRSA)
- Ensure service type is `NodePort`
- Check path is `/*` (required for ALB)

### NGINX 413 Request Entity Too Large

Add annotation:
```yaml
nginx.ingress.kubernetes.io/proxy-body-size: "500m"
```

## Additional Resources

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Traefik Documentation](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
