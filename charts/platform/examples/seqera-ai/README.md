# Seqera AI installation example

This example demonstrates how to enable the Seqera AI [Agent backend](../../charts/agent-backend/),
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

The example doesn't provide values for the Platform chart, but it can be used as a reference for how to set the values for the Seqera AI components.

Private registry credentials are required to pull the Seqera AI images. Refer to the
[VENDORING.md](../../../../VENDORING.md) file for instructions on how to vendor images and charts to
an internal registry.
