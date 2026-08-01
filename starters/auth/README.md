# 🍜 Recipe: OIDC Authentication with Keycloak

Secure a Collector's OTLP receiver with OIDC bearer-token authentication, backed by Keycloak.
This mirrors a common two-tier deployment: an **agent** Collector accepts telemetry locally
without auth, obtains a token via the OAuth2 client-credentials grant, and forwards over TLS to
a **remote** Collector that validates the token before accepting the data.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | oidcauthextension, oauth2clientauthextension, otlp (TLS) |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol-agent.yaml`, `otelcol-remote.yaml`, and the CSR files from this directory
- Docker (for Keycloak), [`cfssl`](https://github.com/cloudflare/cfssl), `curl`, `jq`
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

Run everything **from inside this directory** (the configs reference the certs by relative path):

```terminal
cd starters/auth
```

1. Generate the CA and server certificates:
   ```terminal
   cfssl genkey -initca ca-csr.json | cfssljson -bare ca
   cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
   ```

2. Start Keycloak:
   ```terminal
   docker run -d --name keycloak -p 8080:8080 \
     -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
     quay.io/keycloak/keycloak:26.3 start-dev
   ```

3. Create the realm, the `agent` client, and an audience mapper that stamps `collector` into the
   token (this is what the remote Collector validates):
   ```terminal
   KC=http://localhost:8080
   ADMIN=$(curl -s -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
     $KC/realms/master/protocol/openid-connect/token | jq -r .access_token)
   H="Authorization: Bearer $ADMIN"

   curl -s -X POST $KC/admin/realms -H "$H" -H "Content-Type: application/json" \
     -d '{"realm":"opentelemetry","enabled":true}'

   curl -s -X POST $KC/admin/realms/opentelemetry/clients -H "$H" -H "Content-Type: application/json" -d '{
     "clientId":"agent","secret":"t3UArH3Tg9LuzaMZ0BjtLvxnrE6MRvPt","enabled":true,
     "publicClient":false,"serviceAccountsEnabled":true,
     "standardFlowEnabled":false,"directAccessGrantsEnabled":false}'

   CID=$(curl -s "$KC/admin/realms/opentelemetry/clients?clientId=agent" -H "$H" | jq -r '.[0].id')
   curl -s -X POST $KC/admin/realms/opentelemetry/clients/$CID/protocol-mappers/models \
     -H "$H" -H "Content-Type: application/json" -d '{
     "name":"collector-audience","protocol":"openid-connect","protocolMapper":"oidc-audience-mapper",
     "config":{"included.custom.audience":"collector","access.token.claim":"true","id.token.claim":"false"}}'
   ```

4. Start the remote Collector (TLS + OIDC), then the agent Collector (OAuth2), in two terminals:
   ```terminal
   otelcol-contrib --config otelcol-remote.yaml
   otelcol-contrib --config otelcol-agent.yaml
   ```

5. Send traces to the agent (no auth required at this hop):
   ```terminal
   telemetrygen traces --traces 3 --otlp-insecure --otlp-attributes='recipe="auth"'
   ```

6. Watch the **remote** Collector's console. Its `debug` exporter prints the spans — meaning the
   agent obtained a token, the remote validated its issuer and `collector` audience, and only then
   accepted the data.

## 🎯 Key details

- The **`oauth2client`** extension on the agent does the client-credentials grant against
  `token_url` and attaches the resulting bearer token to every export (`auth.authenticator`).
- The **`oidc`** extension on the remote fetches Keycloak's discovery document from `issuer_url`
  and rejects any token whose `iss` or `audience` doesn't match — which is why step 3's audience
  mapper is mandatory (without it the token's `aud` is `account` and the remote rejects it).
- The token's `iss` claim must equal the remote's `issuer_url` exactly; if you reach Keycloak by a
  different hostname than the agent does, validation fails. Keep both pointing at the same URL.
- Generated `*.pem` files are git-ignored — never commit private keys.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
- Keycloak 26.3
- cfssl v1.6.5
