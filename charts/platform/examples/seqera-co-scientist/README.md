# Seqera Co-Scientist installation example

This example demonstrates how to enable the Seqera Co-Scientist [Agent backend](../../charts/agent-backend/),
[Model Context Protocol server](../../charts/mcp/), and [Portal web
interface](../../charts/portal-web/) using the Platform parent Helm chart and enabling
the respective subcharts. The charts can also be installed without installing the Platform chart,
but some settings need to be configured manually, such as the OIDC initial registration secret,
which is shared between the Platform, MCP and Studios apps.

The agent backend chart requires an encryption key to be set, which can be automatically generated
by the chart if not provided, but it should be set explicitly when using the chart with Kustomize,
otherwise it will be regenerated at each helm upgrade and will cause errors because the encryption
key needs to be stable across upgrades. If created manually, it must be a valid Fernet key, which is
a 32-byte URL-safe base64-encoded string. You can generate a valid Fernet key using the following
Python code:

```python
from cryptography.fernet import Fernet
key = Fernet.generate_key()
print(key.decode())
```

The agent backend requires declaring which provider serves each capability via `inference.provider`,
`embeddings.provider`, and `sandbox.provider`.
`inference.provider` is required: supported values: `bedrock` and `anthropic` (inference only).
Embeddings and sandbox providers are optional (leave empty to disable).
When using Anthropic for inference, set `anthropic.existingSecretName` (or `anthropic.apiKey`).
When using Bedrock for any capability, configure the `bedrock` block accordingly: in particular, an
AWS Bedrock AgentCore runtime ARN must be provided in `bedrock.sandbox.runtimeArn` when sandboxing
is enabled with `sandbox.provider: bedrock`.

When using AWS Bedrock services, the application can optionally be provided with IAM roles to assume
before invoking the bedrock APIs. This is useful to allow the application to access Bedrock
resources in a different account.

The example doesn't provide values for the Platform chart, but it can be used as a reference for how to set the values for the Seqera Co-Scientist components.

Private registry credentials are required to pull the Seqera Co-Scientist images. Refer to the
[VENDORING.md](../../../../VENDORING.md) file for instructions on how to vendor images and charts to
an internal registry.
