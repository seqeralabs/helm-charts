# Vendor charts and images to an internal registry

Seqera Helm charts are published to the OCI registry `public.cr.seqera.io/charts`. For high
availability or air-gapped deployments, we recommend vendoring (replicating) charts into your own
internal OCI registry.

Seqera images are hosted on `cr.seqera.io`. Similarly, we recommend vendoring (replicating) images
into your own internal container registry. Refer to the [Seqera
documentation](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry)
for more information.

## Automatic replication via Container Registry feature - recommended approach

Several container registries offer native replication features that can be used to automatically
replicate images from registries like `public.cr.seqera.io` to your own registry. This is the
recommended approach.

As a reference, here are links to the documentation for setting up replication in some popular
container registries:
- [Amazon Elastic Container Registry (ECR) Replication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/replication.html)
- [Azure Container Registry (ACR) Artifact caching](https://learn.microsoft.com/en-us/azure/container-registry/artifact-cache-overview)
- [Harbor Replication](https://goharbor.io/docs/latest/administration/configuring-replication/)

## Manual replication with Skopeo

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

## Limit versions with SemVer (Skopeo ≥ 1.15)

Starting with Skopeo 1.15+, you can use an yaml sync configuration and the `images-by-semver` option
to filter which chart versions are copied based on SemVer rules (for example, only keep >=1.2.0
<2.0.0). See the [Skopeo
docs](https://github.com/containers/skopeo/blob/v1.20.0/docs/skopeo-sync.1.md?plain=1#L235) for the
exact syntax and detailed examples.
