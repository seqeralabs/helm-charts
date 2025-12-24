# How to Contribute

Any type of contribution is welcome via GitHub Pull Requests. This document outlines the process to
help get your contribution accepted.

### Technical Requirements

When submitting a PR make sure that it:

- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.
- Run the following commands to set up pre-commit hooks:

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

## Helm unittest

### Limitations

helm-unittest only checks the content in the files specified in the `templates` field. This means
that the `fail` functions in the NOTES.txt files are not executed unless NOTES.txt is in the
`templates` field.
See for example how the configmap is rendered when no database details are provided: https://github.com/seqeralabs/helm-charts/pull/41/files/7552fda982f16c1f4f878d97dfba98a57264f231#diff-d4485ab61726ba6c92119e7bf10c9bad7280aa58a4246ab76a8c3711d1e50ef1R10
That expansion shouldn't happen because the database fields are required, but that's a limitation
(feature?) of helm-unittest.

### Snapshots

Snapshot files are useful for testing complex outputs or large data structures, as they allow
you to easily compare the actual output of your Helm templates against the expected output stored
in the snapshot files previously generated. These snapshots can be updated as needed when the
Helm templates change.

When using the `helm-unittest` plugin, you can create snapshot files to store expected outputs
for your tests. To create or update snapshot files, run the following command in the chart
directory:

```console
$ make test-update-snapshots
```

This will generate or update the snapshot files in the `tests/snapshots` directory.
Snapshot files should be committed to the repository to ensure that tests can be run consistently
across different environments and over time.
