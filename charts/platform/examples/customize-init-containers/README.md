# TLS Authentication to AWS RDS

This example demonstrates how to connect the Platform init containers to AWS RDS (MySQL) endpoints
that require TLS with certificate verification.

## Background

AWS RDS uses TLS certificates signed by the AWS Certificate Authority. The standard `mysql:9` init
container image does not include the AWS CA bundle by default, so certificate verification fails
unless the CA certificate is made available inside the container.

The MariaDB JDBC driver (used by the Platform backend and migration container) also requires the CA
certificate to be provided via the `serverSslCert` connection option.

AWS ElastiCache Redis uses a certificate signed by a public CA that is already trusted by the
`redis:7-alpine` image and the JVM default trust store, so no custom CA bundle is needed for Redis.

The approach used here:

1. An `extraInitContainer` (runs **before** the `waitFor*` containers) fetches the AWS CA bundle
   from the AWS trust store URL and writes it to a shared `emptyDir` volume.
2. The `waitForMySQL` init container mounts that volume and passes `--ssl-ca` and `--ssl-mode` via
   `MYSQL_EXTRA_ARGS`.
3. The `migrate-db` init container and the main `backend` and `cron` containers mount that volume
   so the MariaDB JDBC driver can verify the RDS certificate via `serverSslCert`.

## Prerequisites

- Your cluster nodes must have outbound HTTPS access to `https://truststore.pki.rds.amazonaws.com`, OR the CA bundle must be pre-loaded into a ConfigMap or Secret.
- AWS RDS MySQL must be configured with `require_secure_transport = ON`.

## Fetch the CA bundle at pod startup (online approach)

This approach downloads the AWS CA bundle dynamically. It requires outbound internet access from the
init container.

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
Then reference the ConfigMap in the values file instead of using an init container to fetch it.
See [aws-tls-offline.yaml](aws-tls-offline.yaml).

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
and the `--ssl-ca` path are consistent.

### `File not found for option serverSslCert`

The `extraVolumeMounts` for `/certs` is missing from the `backend` or `cron` main container, or
from cron's `dbMigrationInitContainer`. All three need the volume mounted.

## Additional Resources

- [AWS RDS SSL/TLS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)
- [MariaDB Connector/J TLS options](https://mariadb.com/kb/en/about-mariadb-connector-j/#tls-ssl-related-options)
