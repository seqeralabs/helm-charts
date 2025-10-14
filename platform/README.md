## NextFlow Tower Helm Chart

This is a Helm Chart that contains all the needed components to run Tower into a kubernetes cluster.

## Requirements

* Kubernetes 1.19+
* Helm 3.2.0+
* PV provisioner support in the underlying infrastructure

## Installing the chart

Add the Seqera Helm chart repository to your collection and install this chart with:

```console
helm repo add --username '<username>' --password '<password>' seqeralabs https://cr.seqera.io/chartrepo/public
helm install <release-name> seqeralabs/tower
```

Some useful options to add: you may want to let kubernetes upgrade an existing installation if
already present (use `upgrade --install` instead of `install`), create a personalized values file
with the desired values for your environment (e.g. Ingress annotations, etc), you may want to define
a specific version of the chart to use, or use a dedicated namespace for the installation and create
it on-demand if it doesn't exist:

```console
helm upgrade <release-name> seqeralabs/tower  \
        --install                             \
        --values <values-file.yaml>           \
        --version 0.1.2                       \
        --namespace <namespace>               \
        --create-namespace
```

To personalize the values file for your deployment copy the `values.yaml` file in this repo and
adapt it to your needs: the default values defined there are applied anyway, so there's no need to
re-define them in your configuration file.

## Uninstalling the chart

```console
helm uninstall <release-name> --namespace <namespace>
```

## Troubleshooting

1. Helm app installation
  * Q: The values I set aren't applied.
    - A: Use `helm template --debug`, which at the top prints out the `USER-SUPPLIED VALUES`, what
      you provide with your own values file, and the `COMPUTED VALUES`, the result from your values
      file and the default values of the chart, check that your values are correctly overwriting the
      default values.

  * Q: `helm install` breaks with some YAML to JSON conversion errors.
    - A: Double check that your YAML code is correctly formatted. Use `helm template --debug` to
      print how the manifests would be rendered, and check with a linter that the result looks
      correct.

2. Service/Ingress
  * Q: The kubernetes Service doesn't work.
    - A: Check that the Service object is correctly defined: note that `targetPort` in a Service has
      to match the port the process is listening on inside the container, while `port` is the port
      the kubernetes Service will listen on and will forward to the container. If the definitions
      look good, first check the logs of the container, then `exec` a shell inside the pod and test
      with `curl`/`wget` that the service is working fine locally. If that's ok, check that the
      Service object has been configured correctly: `exec` a shell into a nearby pod in the same
      namespace, and test that the Service object is working correctly.

  * Q: The kubernetes Ingress doesn't work.
    - A: If the Service works fine (see previous point), check the Ingress with a `describe`: it may
      complain that there are multiple `defaultBackend` defined in the cluster. If it prints
      `Successfully reconciled`, then the configuration is ok, but the Ingress may still not work if
      you changed the Service object compared to the first time the Ingress was deployed. In that
      case delete the Ingress (you may need to edit it to remove delete protections/finalizers) and
      reapply the Helm chart (`helm upgrade --install` is useful for this).
