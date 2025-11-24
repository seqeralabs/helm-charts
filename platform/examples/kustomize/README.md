# Kustomize Integration Example for Seqera Platform Helm Chart

This directory contains a complete example of how to use the Seqera Platform Helm chart with [Kustomize's](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) `helmCharts` feature.

## Prerequisites

1. **Kustomize** v5.0+ with Helm support
2. **Helm** v3 (required by Kustomize for chart rendering)
3. **kubectl** configured to access your cluster

## How It Works

### 1. Helm Chart Loading

The `helmCharts` block in [kustomization.yaml](kustomization.yaml) instructs Kustomize to:
- Pull the Helm chart from the OCI registry
- Apply values from [values.yaml](values.yaml)
- Override with inline values from `valuesInline`
- Render the chart templates

```yaml
helmCharts:
  - name: platform
    repo: oci://public.cr.seqera.io/charts
    version: 0.14.5
    releaseName: seqera-platform
    namespace: seqera-platform
    valuesFile: values.yaml
    # valuesInline:
    #   optionally override values here, but usually it's not needed
```

### 2. Values Hierarchy

Values are applied in this order (later overrides earlier):
1. Chart's default `values.yaml` (built into the chart)
2. Your `valuesFile: values.yaml` (this directory)
3. `valuesInline` in [kustomization.yaml](kustomization.yaml)

### 3. Patching Strategy

This example demonstrates two patching approaches:

#### Strategic Merge Patches
Files in `patchesStrategicMerge` merge with existing resources:
- [backend-deployment-patch.yaml](patches/backend-deployment-patch.yaml) - Adds sidecars, env vars, volumes
- [add-monitoring-labels.yaml](patches/add-monitoring-labels.yaml) - Adds monitoring labels

Strategic merge is good for:
- Adding new fields
- Merging lists intelligently
- More readable patches

#### JSON 6902 Patches
Files in `patchesJson6902` make precise modifications:
- [backend-resources-patch.yaml](patches/backend-resources-patch.yaml) - Modifies specific resource values

JSON 6902 is good for:
- Precise path-based operations
- Replacing specific values
- When strategic merge doesn't work

### 4. Additional Resources

Resources not provided by the Helm chart can be added:
- [network-policy.yaml](additional-resources/network-policy.yaml) - Adds NetworkPolicy

### 5. ConfigMap Generation

ConfigMaps can be generated from files:
```yaml
configMapGenerator:
- name: platform-extra-config
  files:
  - config/custom-config.properties
```

## Usage

### Build and View Output

Preview the rendered manifests:

```bash
# From this directory
kubectl kustomize --enable-helm .

# Or using kustomize directly
kustomize build --enable-helm .
```

### Apply to Cluster

Deploy to your Kubernetes cluster:

```bash
kubectl kustomize --enable-helm . | kubectl apply -f -
```

### Dry Run

Test without applying:

```bash
kubectl kustomize --enable-helm . | kubectl apply -f - --dry-run=server -o yaml
```

## Using kustomize to setup different environments

https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/

Create overlay directories:

```
kustomize/
├── base/                    # This directory
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── dev-values.yaml
    ├── staging/
    │   ├── kustomization.yaml
    │   └── staging-values.yaml
    └── production/
        ├── kustomization.yaml
        └── prod-values.yaml
```

In `overlays/production/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namespace: seqera-platform-prod

helmCharts:
  - name: platform
    repo: oci://public.cr.seqera.io/charts
    version: 0.14.5
    releaseName: seqera-platform
    valuesFile: prod-values.yaml

commonLabels:
  environment: production
```

## Troubleshooting

### Patch Not Applying

Check resource names match:

```bash
# List resources created by Helm chart
kubectl kustomize --enable-helm . | grep "kind: Deployment" -A 2

# Ensure patch metadata.name matches exactly
```

### Values Not Taking Effect

Check values hierarchy:

```bash
# See final values used by Helm
helm template seqera-platform oci://public.cr.seqera.io/charts/platform \
  --version 0.14.5 \
  -f values.yaml \
  --set global.platformExternalDomain=example.net
```

## Resources

- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [Kustomize Helm Integration](https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#helm-chart-inflation)
- [Seqera Platform Helm Chart](https://github.com/seqeralabs/helm-charts)
- [Strategic Merge Patch](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#patchstrategicmerge)
- [JSON 6902 Patch](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#patchjson6902)

## Next Steps

1. Copy this directory as a template
2. Modify [values.yaml](values.yaml) for your environment
3. Adjust patches in `patches/` directory
4. Add any additional resources needed
5. Test with `kubectl kustomize --enable-helm .`
6. Deploy with `kubectl kustomize --enable-helm . |kubectl apply -f -`
