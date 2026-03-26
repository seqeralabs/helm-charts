# Seqera AI installation example

This example demonstrates how to enable the Seqera AI [Agent backend](../../charts/agent-backend/),
[Model Context Protocol server](../../charts/mcp/), and [portal web
interface](../../charts/portal-web/) using the Platform parent Helm chart and enabling
the respective subcharts, but the charts can also be installed independently from Platform.

Private registry credentials are required to pull the Seqera AI images. Refer to the
[VENDORING.md](../../../../VENDORING.md) file for instructions on how to vendor images and charts to
an internal registry.
