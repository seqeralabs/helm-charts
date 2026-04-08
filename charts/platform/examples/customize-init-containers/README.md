# TLS Authentication to AWS RDS

This example demonstrates how to connect Seqera products to AWS RDS (MySQL) endpoints
that require TLS with certificate verification.

## Background

AWS RDS uses TLS certificates signed by the AWS Certificate Authority (CA). The default `mysql:9`
init container image used by Platform does not include the AWS CA bundle, so certificate
verification fails unless the CA certificate is made available inside the container.

The MariaDB JDBC driver (used by the Platform backend and migration container) also requires the CA
certificate to be provided via the `serverSslCert` connection option.

AWS ElastiCache Redis uses a certificate signed by a public CA that is already trusted by the
`redis:7-alpine` image and the JVM default trust store, so no custom CA bundle is needed to make
Platform or other products communicate with AWS ElastiCache.

The approach used here:

1. A CA bundle is made available on a shared volume, either by an `extraInitContainer` that
   fetches it at pod startup (online approach) or by mounting a pre-populated ConfigMap
   (offline approach).
2. The `waitForMySQL` init container mounts that volume and passes `--ssl-ca` and `--ssl-mode` via
   `MYSQL_EXTRA_ARGS`.
3. The `migrate-db` init container and the main `backend` and `cron` containers mount that volume
   so the MariaDB JDBC driver can verify the RDS certificate via `serverSslCert`.
4. The `pipeline-optimization` subchart (if enabled) mounts the same volume and references the
   certificate via its `database.sslCa` and `platformDatabase.sslCa` options.
5. The `agent-backend` subchart (if enabled) follows the same pattern as `pipeline-optimization`:
   a `fetch-rds-ca` init container writes the bundle to a shared volume, and `database.sslCa`
   points to that path.

## Prerequisites

The TLS Certificate Authority (CA) bundle must be available to the init containers and main
containers. This bundle can be obtained from AWS by either fetching it at pod startup (requires
outbound internet access) or pre-loading it into a ConfigMap or Secret (for air-gapped environments
or to reduce the number of dependencies before a pod starts).

The database connection must be configured to use TLS. Set the following under
`platformDatabase.connectionOptions.mariadb` in your values file:

```yaml
platformDatabase:
  connectionOptions:
    mariadb:
      - permitMysqlScheme=true
      - sslMode=verify-full
      - serverSslCert=/certs/ca-bundle.pem
```

`sslMode=verify-full` enables TLS, verifies the server certificate against the CA bundle, and
checks that the hostname matches the certificate. The `serverSslCert` path must match the
`mountPath` used for the CA bundle volume.

Redis on AWS ElastiCache does not require a custom CA bundle. Setting `redis.enableTls: true`
is sufficient:

```yaml
redis:
  enableTls: true
```

`pipeline-optimization` and `agent-backend` use their own database connections and must each
have TLS enabled separately, pointing `sslCa` to the CA bundle path on their mounted volume:

```yaml
pipeline-optimization:
  database:
    enableTls: true
    sslCa: /certs/ca-bundle.pem
  platformDatabase:
    enableTls: true
    sslCa: /certs/ca-bundle.pem

agent-backend:
  database:
    enableTls: true
    sslCa: /certs/ca-bundle.pem
```

## Fetch the CA bundle at pod startup (online approach)

This approach downloads the AWS CA bundle dynamically using a `fetch-aws-ca` init container that
runs before the built-in `waitFor*` containers. It requires outbound internet access from the
pod at startup time.

Key points:

- An `emptyDir` volume named `aws-ca-bundle` is declared on both `backend` and `cron` deployments.
- A user-supplied `initContainers` entry (`fetch-aws-ca`) writes the bundle to `/certs/ca-bundle.pem`
  on the shared volume. Because user-supplied init containers are placed before the built-in
  `waitFor*` containers, the certificate is present on disk when the readiness checks run.
- `extraVolumeMounts` on `backend`, `cron`, and `cron.dbMigrationInitContainer` make the volume
  available at `/certs` so the MariaDB JDBC driver can read it.
- `initContainerDependencies.waitForMySQL.extraVolumeMounts` mounts the same volume into the
  `waitForMySQL` init container so `mysql` CLI can verify the server certificate.
- For `pipeline-optimization` and `agent-backend`, a separate `fetch-rds-ca` init container
  writes the bundle to `/rds-ca/rds-ca-bundle.pem` on an `rds-ca-bundle` `emptyDir` volume,
  referenced by `database.sslCa` (and `platformDatabase.sslCa` for `pipeline-optimization`).

See [aws-tls-online.yaml](aws-tls-online.yaml).

## Pre-load the CA bundle into a ConfigMap (offline / air-gapped approach)

Download the AWS CA bundle once and store it in a ConfigMap:

```bash
curl -sSf https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem \
  -o aws-rds-us-east-1-ca-bundle.pem

kubectl create configmap aws-rds-us-east-1-ca-bundle \
  --from-file=ca-bundle.pem=aws-rds-us-east-1-ca-bundle.pem \
  --namespace <your-namespace>
```

A global bundle is also available covering all AWS RDS regions, see the [AWS
documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html).

Key points:

- No init container is needed to fetch the cert at runtime, since the ConfigMap is mounted directly
  as a volume on `backend`, `cron`, `pipeline-optimization`, and `agent-backend`.
- The ConfigMap volume must be declared on every deployment that runs the `waitFor*` init
  containers. For the platform chart that means both `backend` and `cron`.
- `extraVolumeMounts` on `backend`, `cron`, and `cron.dbMigrationInitContainer` expose the bundle
  at `/certs` so the MariaDB JDBC driver can read it via `serverSslCert=/certs/ca-bundle.pem`.
- `initContainerDependencies.waitForMySQL.extraVolumeMounts` mounts the volume into the
  `waitForMySQL` init container at `/certs`.
- For `pipeline-optimization`, the same ConfigMap is mounted at `/certs` and referenced by
  `database.sslCa` and `platformDatabase.sslCa`.
- For `agent-backend`, the same ConfigMap is mounted at `/certs` and referenced by
  `database.sslCa`.

You can also store the CA bundle within your custom `values.yaml` file and let Helm create the
ConfigMap using the `.extraDeploy` option, avoiding the manual `kubectl create configmap` step.

See [aws-tls-offline.yaml](aws-tls-offline.yaml).

## Choosing between online and offline

| | Online | Offline (ConfigMap) |
|---|---|---|
| Internet access required | Yes (at pod startup) | No |
| CA bundle stays current | Yes (fetched each time) | No (manual refresh needed) |
| Air-gapped environments | Not suitable | Suitable |
| Extra init container | Yes (`fetch-aws-ca`) | No |
| ConfigMap management | No | Yes |

## Troubleshooting

### Init container stuck in `CrashLoopBackOff`

Check logs of the `fetch-aws-ca` init container:

```bash
kubectl logs <pod-name> -c fetch-aws-ca
```

Common causes:
- No outbound internet access to the AWS trust store URL (use the offline approach instead)
- Wrong region in the URL (update to match your RDS region)

### `ERROR 2026 (HY000): SSL connection error`

The CA cert path in `MYSQL_EXTRA_ARGS` does not match the `mountPath`. Verify the volume mount
and the `--ssl-ca` path are consistent. Both must point to the same file, e.g.:

```yaml
initContainerDependencies:
  waitForMySQL:
    extraEnv:
      - name: MYSQL_EXTRA_ARGS
        value: "--ssl-ca=/certs/ca-bundle.pem --ssl-mode=VERIFY_IDENTITY"
    extraVolumeMounts:
      - name: aws-ca-bundle   # or aws-rds-us-east-1-ca-bundle for the offline approach
        mountPath: /certs
        readOnly: true
```

### `File not found for option serverSslCert`

The `extraVolumeMounts` for `/certs` is missing from the `backend` or `cron` main container, or
from cron's `dbMigrationInitContainer`. All three need the volume mounted at the same path used
in `serverSslCert`.

### Redis TLS connection refused

Ensure `redis.enableTls: true` is set. AWS ElastiCache uses a publicly-trusted CA so no custom
certificate is needed, but TLS must be enabled explicitly.

## Additional Resources

- [AWS RDS SSL/TLS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)
- [MariaDB Connector/J TLS options](https://mariadb.com/kb/en/about-mariadb-connector-j/#tls-ssl-related-options)
