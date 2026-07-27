# Private / internal CA trust

Deployments behind an enterprise PKI, or behind a firewall performing HTTPS interception, present
certificates signed by a CA that is in no public trust store. Seqera components then fail to reach
each other and to reach internal services.

`global.trustStore` distributes that CA to every component the chart deploys.

## The two trust problems

Conflating these is the usual reason a fix appears not to work.

| | Mechanism | Covers |
|---|---|---|
| Database connection | The driver's own option — `platformDatabase.connectionOptions.mariadb` `serverSslCert`, or a subchart's `database.sslCa` | That JDBC connection, and nothing else |
| Every other outbound HTTPS call | `global.trustStore` | Wave, Connect, internal OIDC, internal registries, TLS-inspecting proxies |

The JVM consults only its own trust store, so a PEM on disk does nothing for the second row. The
symptom of getting this wrong is `PKIX path building failed: unable to find valid certification
path to requested target` from a component whose database connection works perfectly.

The two are independent. Set both when the database certificate is also signed by the internal CA —
see [private-ca.yaml](private-ca.yaml). For AWS RDS or Azure Database for MySQL, keep the database
option pointed at that provider's own bundle; the internal CA does not sign those certificates.

## Usage

Supply the CA inline and let the chart create the ConfigMap:

```yaml
global:
  trustStore:
    enabled: true
    certificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
```

Or reference an object you manage yourself:

```yaml
global:
  trustStore:
    enabled: true
    existingConfigMap: corporate-ca   # or existingSecret
    key: ca.crt
```

See [private-ca.yaml](private-ca.yaml) and [existing-configmap.yaml](existing-configmap.yaml).

Enabling the flag without a CA source renders nothing, rather than producing pods that reference a
volume which does not exist.

## What the chart does

| Component | Mechanism |
|---|---|
| `backend`, `cron`, `wave` | Java trust store built by a `build-trust-store` init container, selected with `JAVA_TOOL_OPTIONS` |
| cron's `migrate-db` init container | Same trust store — it runs after `build-trust-store` |
| `agent-backend`, `mcp`, `pipeline-optimization` | System-plus-private PEM built by a `build-ca-bundle` init container, selected with `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, and `CURL_CA_BUNDLE` |
| `portal-web` | Private PEM selected with Node.js's additive `NODE_EXTRA_CA_CERTS` |
| `frontend` | Nothing. It proxies to the backend over the cluster network and makes no outbound TLS calls |

Two details worth knowing:

- **The store is seeded, not replaced.** The init container copies the JRE's existing `cacerts` and
  adds your CA. Replacing the bundle would drop every public root and break outbound calls to
  legitimately public endpoints — and it presents as an unrelated network fault, not a trust error.
- **PEM bundles are augmented too.** Non-JVM services that use conventional CA-bundle variables
  receive their image's system roots plus your private CA. Node.js uses its native additive setting.
- **Each component seeds from its own image.** A trust store built from a different JDK carries that
  vendor's set of public roots, and Seqera components do not all ship the same base image. Override
  `global.trustStore.java.image` only when a component image does not ship `keytool`, and match the
  vendor and major JDK version.

## Verify

```shell
helm template seqera seqera/platform -f private-ca.yaml \
  | grep -A2 'name: build-trust-store'
```

In a running cluster, confirm the CA is present in the generated store:

```shell
kubectl exec -n platform deploy/seqera-platform-backend -- \
  keytool -list -alias seqera-trust-store-ca \
  -keystore /opt/seqera/truststore/cacerts -storepass changeit
```

## Operational notes

- **`JAVA_TOOL_OPTIONS` is logged.** The JVM writes `Picked up JAVA_TOOL_OPTIONS: ...` to stderr at
  startup for every affected component. Expected, not an error.
- **`JAVA_TOOL_OPTIONS` does not merge.** If another overlay sets it too, one silently wins and the
  other's flags vanish. Check for an existing value before combining this with other values files.
- **Rotation requires a restart.** The trust store is built once at pod startup, so an updated
  ConfigMap or Secret is not picked up by running pods.
- **The store password is not a secret.** It protects the store's integrity, not its
  confidentiality. `changeit` is the JRE default carried over from the seeded bundle.

## Not covered

**Wave build pods.** Wave launches BuildKit in pods outside this chart, so they never see this
trust store. A push to a registry behind the internal CA still fails with `x509: certificate signed
by unknown authority`. Those need a BuildKit image with the CA in its system trust bundle, selected
with `wave.build.buildkit-image`. BuildKit has no supported way to supply a CA to a rootless daemon
without rebuilding the image
([moby/buildkit#6068](https://github.com/moby/buildkit/issues/6068)).

**Studios sessions.** Studio containers run in the compute environment, not the cluster. The CA has
to reach them through the Studio image or the compute environment configuration.

**Nextflow launcher and compute nodes.** Same — these run in the compute environment and are
configured there.
