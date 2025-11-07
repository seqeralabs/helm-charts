# How to Contribute

To contribute to this repository, first run the following commands to set up pre-commit hooks:

```console
$ pre-commit install
$ pre-commit install-hooks
```

To build the charts locally, use `make` from each chart directory.

The charts in this repository use [helm-unittest](https://github.com/helm-unittest/helm-unittest/)
for unit testing. To run the tests, use `make test` from each chart directory. `make
install-unittest-plugin` will install the plugin if needed.

These charts will try to adhere to SemVer versioning as much as possible, starting from version
1.0.0 of each chart. Please refer to the [Semantic Versioning 2.0.0](https://semver.org/)
documentation for more details.
When submitting a pull request, please bump the chart version in the `Chart.yaml` file according to
the type of change you are making (patch, minor, major).

Each push to a branch will trigger GitHub Actions workflows to lint and test the charts and verify
that no clash exists in the chart versions. Pull requests merging to the `main` branch will also trigger
the publication of the charts to the OCI registry at `public.cr.seqera.io/charts`.
