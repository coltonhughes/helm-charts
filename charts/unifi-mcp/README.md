# unifi-mcp

Deploys [enuno/unifi-mcp-server](https://github.com/enuno/unifi-mcp-server) in
streamable HTTP mode. The MCP endpoint is available at `/mcp` and is protected
by the server's bearer token authentication.

## Prerequisites

Create a Secret containing a UniFi API key and a separate, high-entropy MCP
bearer token. The chart intentionally does not render either credential.

```sh
kubectl -n unifi-mcp create secret generic unifi-mcp \
  --from-literal=UNIFI_API_KEY='...' \
  --from-literal=MCP_AUTH_TOKEN='...'
```

For local-controller mode, the default, also set `container.env.UNIFI_LOCAL_HOST`
to the controller or gateway address reachable from the cluster. To use a
different Secret or key names, configure `auth.existingSecret`, `auth.apiKeyKey`,
and `auth.mcpAuthTokenKey`.

## HTTPRoute

Enable an HTTPRoute with a Gateway parent and hostname:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: internal
      namespace: gateway
  hostnames:
    - unifi-mcp.example.com
```

Clients connect to `https://unifi-mcp.example.com/mcp` and send
`Authorization: Bearer <MCP_AUTH_TOKEN>`. Terminate TLS at the Gateway. The
chart defaults to `UNIFI_READ_ONLY=true`; switch it off only for a deliberately
write-capable deployment.
