# Seqera Community Kubernetes Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The code is provided as-is with no warranties.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add seqeralabs https://seqeralabs.github.io/helm-charts
```

You can then run `helm search repo seqeralabs` to see the charts.

### OCI registry

Charts are also published as OCI artifacts to `public.cr.seqera.io/charts`. You can install
directly from the OCI registry without adding the Helm repo, for example:

```console
helm install my-release oci://public.cr.seqera.io/charts/platform --version <version>
```

For high availability or air-gapped deployments, you can vendor (replicate) the charts into your
own internal OCI registry. See the [vendoring documentation](https://github.com/seqeralabs/helm-charts/blob/master/VENDORING.md) for details.

<!-- Keep full URL links to repo files because this README syncs from master to gh-pages.  -->

Chart documentation is available in [seqeralabs directory](https://github.com/seqeralabs/helm-charts/blob/master/README.md).

## Contributing

<!-- Keep full URL links to repo files because this README syncs from master to gh-pages.  -->

We'd love to have you contribute! Please refer to our [contribution guidelines](https://github.com/seqeralabs/helm-charts/blob/master/CONTRIBUTING.md) for details.

## License

<!-- Keep full URL links to repo files because this README syncs from master to gh-pages.  -->

[Apache 2.0 License](https://github.com/seqeralabs/helm-charts/blob/master/LICENSE).
