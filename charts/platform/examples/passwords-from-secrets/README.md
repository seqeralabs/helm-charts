# Provide passwords with Kubernetes Secrets

Storing passwords in a helm chart values files is not secure, as these files are often checked into
source control. Instead, you can store passwords in Kubernetes Secrets and reference them in the
Platform helm chart values.

This example shows how to use Kubernetes Secrets to provide passwords to the Platform helm chart.

Multiple passwords are required by the Platform components, e.g. database passwords, (optional)
redis passwords, the JWT seed value, etc. This example shows how to create a Kubernetes Secret
containing all required passwords, and how to reference these passwords in the Platform helm chart
values.

In most production deployments, a secure method of storing and retrieving passwords should be used
instead of manually creating Kubernetes Secrets. Just to provide an example, the [External Secrets
Operator](https://external-secrets.io/) could be used along with a secret store such as AWS Secrets
Manager, HashiCorp Vault, etc. This example does not cover that, but focuses on how to reference
Kubernetes Secrets in the Platform helm chart values.

## Create a Kubernetes Secret with passwords

Create a file named `passwords-secret.yaml` with content similar to the following, replacing the placeholder values with your actual passwords and secret values:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: platform-passwords
stringData:
  TOWER_LICENSE: your_tower_license
  # Here the platform database password entry uses a different key than the default
  # TOWER_DB_PASSWORD, to show that custom keys can be used in the helm chart values.
  database-password: your_database_password
  redis-password: your_redis_password
  jwt-seed: your_jwt_seed_value
  TOWER_CRYPTO_SECRETKEY: your_tower_crypto_secretkey
  TOWER_SMTP_PASSWORD: your_tower_smtp_password
  # If you want to set a custom OIDC registration token it then needs to be set on Studios and MCP
  # as well, see below.
  OIDC_CLIENT_REGISTRATION_TOKEN: your_oidc_client_registration_token

  # Agent backend specific secrets
  AGENT_BACKEND_DB_PASSWORD: your_agent_backend_db_password
  # ANTHROPIC_API_KEY: your_anthropic_api_key  # set this if you want to use the Anthropic LLM provider
  AGENT_BACKEND_TOKEN_ENCRYPTION_KEY: your_agent_backend_token_encryption_key # this needs to be a valid Fernet key, see the agent-backend helm chart values for more information

  # MCP specific secrets
  MCP_OAUTH_JWT_SEED: your_mcp_oauth_jwt_seed_value
```

The example above contains some sensitive values used by multiple charts, and can be referred to in
each chart values files. Alternatively, multiple Secrets can be created if you prefer to separate
the sensitive values for each chart.
The example above does not include all possible sensitive values that can be used in the Platform
helm chart, but only the most common ones. More sensitive values can be added to the Secret as
needed, and referenced in the helm chart values files as shown below, e.g. the Redis authentication
password, if the cache was configured to require a password to access it.

More details about the required content to store in each Secret can be found in the helm chart values files for each chart.
Then, create the Secret in your Kubernetes cluster:

```bash
kubectl -n <your-namespace> apply -f passwords-secret.yaml
```

The secret named `platform-passwords` is now present in the cluster in the `<your-namespace>`
namespace and can be referenced in your helm chart values.

## Reference the passwords in the Platform helm chart values

In the values file for your Platform helm chart installation, you can reference the
passwords stored in the Secret above, along with other required Platform configuration
values (not shown here for brevity):

```yaml
platformDatabase:
  host: ...
  # other required values are omitted for brevity
  existingSecretName: platform-passwords
  existingSecretKey: database-password  # Here we need to specify the custom key used in the Secret for the database password, as it is not the default key `TOWER_DB_PASSWORD`.

redis:
  # ...
  existingSecretName: platform-passwords
  existingSecretKey: redis-password

platform:
  licenseSecretName: platform-passwords
  # The default key `TOWER_LICENSE` was used in the Secret, so there is no need to specify it again here.
  # licenseSecretKey: TOWER_LICENSE

  jwtSeedSecretName: platform-passwords
  jwtSeedSecretKey: jwt-seed

  cryptoSeedSecretName: platform-passwords
  # cryptoSeedSecretKey: TOWER_CRYPTO_SECRETKEY # Default key was used, this can be omitted

  smtp:
    existingSecretName: platform-passwords
    # existingSecretKey: TOWER_SMTP_PASSWORD # Default key was used, this can be omitted

  # The following needs to be made explicit on Studios and MCP chart values if a custom OIDC
  # registration token is used; by default the chart autogenerates the value and configures
  # .studios.proxy.oidcClientRegistrationTokenSecret* and .mcp.oidcToken.existingSecret* to use the
  # auto-generated value of the "parent" Platform chart.
  oidcClientRegistrationTokenSecretName: enterprise-stage

studios:
  enabled: true
  # ...
  proxy:
    oidcClientRegistrationTokenSecretName: platform-passwords
    oidcClientRegistrationTokenSecretKey: OIDC_CLIENT_REGISTRATION_TOKEN

agent-backend:
  enabled: true
  # ...
  database:
    existingSecretName: platform-passwords
    # existingSecretKey: AGENT_BACKEND_DB_PASSWORD # Default key was used, this can be omitted
  tokenEncryptionKeyExistingSecretName: platform-passwords

mcp:
  enabled: true
  # ...
  oauth:
    jwtSeedSecretName: platform-passwords
  oidcToken:
    existingSecretName: platform-passwords
    existingSecretKey: OIDC_CLIENT_REGISTRATION_TOKEN
```

The helm chart allows you to customize the secret keys used for each sensitive value.
This will make the Platform helm chart use the passwords stored in the `platform-passwords`
Kubernetes Secret by setting the appropriate environment variables on the required Platform
components.

Note that only the platform database and the license are mandatory, the JWT seed and crypto key will
be auto-generated by the helm chart if not provided, and SMTP and Redis authentication are optional
components.
