# Seqera Helm charts library

This repository contains Helm charts for deploying Seqera products on Kubernetes clusters.

Currently, it includes charts for:
- [Platform](./platform/README.md): Seqera Platform for workflow orchestration and management.
- [Pipeline Optimization](./platform/charts/pipeline-optimization/README.md): A service to optimize
  Nextflow pipelines running on Platform - internally referred to as Groundswell.

The Platform chart is the main chart, and other charts can be deployed as sub-charts of Platform.
However, the sub-charts are also designed to be deployed independently from the Platform chart, if
desired.

Each chart comes with its own README file containing specific instructions and details. Some example
scenarios are also provided in the `examples/` directory to help you configure and deploy the
charts in different environments.

## Vendoring Seqera container images and charts

Refer to the [vendoring documentation](./VENDORING.md) for instructions on how to vendor Seqera
container images and charts to your private registry.

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

All charts in this repository are licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for details.

## Development

If interested in contributing to this repository, please follow the contribution guidelines and the
recommendations outlined in [CONTRIBUTING](./CONTRIBUTING.md).

> We'd love your feedback! Please test the charts with your use cases and [report any
> issues](https://github.com/seqeralabs/helm-charts/issues) you encounter. Your input
> will help us build a better product.
