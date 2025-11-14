# Seqera Helm charts library

This repository contains Helm charts for deploying Seqera Labs products and related software on
Kubernetes clusters.

Currently, it includes charts for:
- [Platform](./platform/README.md): Seqera Labs Platform for workflow orchestration and management.

More products will be added in the future.

## Vendor charts to an internal registry

Seqera Helm charts are published to the OCI registry `public.cr.seqera.io/charts`. For high
availability or air-gapped deployments, we recommend vendoring (replicating) charts into your own
internal OCI registry.

### Recommended approach

Use [Skopeo](https://github.com/containers/skopeo) to automate and keep your internal registry in
sync. For example to synchronize all releases of the `platform` chart from the public Seqera
registry to your internal registry:

```console
skopeo login [...] internal-registry.example.com
skopeo sync --scoped --src docker --dest docker public.cr.seqera.io/charts/platform internal-registry.example.com
```

This will copy every version of `public.cr.seqera.io/charts/platform` into the repository
`internal-registry.example.com/public.cr.seqera.io/charts/platform`.

Note that charts may include dependencies to other charts in the same registry, so make sure to
vendor all charts you plan to use: refer to the "Requirements" section in each chart's README file.

### Limit versions with SemVer (Skopeo ≥ 1.15)

Starting with Skopeo 1.15+, you can use an yaml sync configuration and the `images-by-semver` option
to filter which chart versions are copied based on SemVer rules (for example, only keep >=1.2.0
<2.0.0). See the [Skopeo
docs](https://github.com/containers/skopeo/blob/v1.20.0/docs/skopeo-sync.1.md?plain=1#L235) for the
exact syntax and detailed examples.

## Licensing

All charts in this repository are licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for details.

## Development

If contributing to this repository, please follow the contribution guidelines outlined in the
[CONTRIBUTING](./CONTRIBUTING.md) file.
