# 🍜 Recipe: OIDC Authentication with Keycloak

This recipe demonstrates how to secure OpenTelemetry Collector receivers using OIDC authentication with Keycloak. Based on the [blog post by Juraci Paixão Kröhling](https://medium.com/opentelemetry/securing-your-opentelemetry-collector-1a4f9fa5bd6f), this recipe provides enterprise-grade authentication suitable for production deployments.

The recipe focuses on **OIDC Authentication** with Keycloak, demonstrating:
- Manual Keycloak realm and client configuration
- Agent and remote collector architecture
- Token-based authentication for secure telemetry ingestion
- TLS encryption for secure communication

The recipe includes both agent and remote collector configurations to demonstrate a realistic deployment architecture where agents collect telemetry locally (without authentication) and forward it to remote collectors (with authentication).

## 🧄 Ingredients

- The `otelcol-contrib` distribution
- The `telemetrygen` tool for generating test telemetry
- Docker for running Keycloak and LGTM stack
- `cfssl` for generating TLS certificates
- `jq` for parsing JSON responses from Keycloak

## 🥣 Preparation

1. Start Keycloak manually:
   ```bash
   docker run -d --name keycloak \
     -p 8080:8080 \
     -e KEYCLOAK_ADMIN=admin \
     -e KEYCLOAK_ADMIN_PASSWORD=admin \
     -e KC_DB=dev-mem \
     quay.io/keycloak/keycloak:26.3 start-dev
   ```

2. **Configure Keycloak Realm and Client**:

3. Generate TLS certificates for secure communication:
   ```bash
   cfssl genkey -initca ca-csr.json | cfssljson -bare ca
   cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
   cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
   ```

5. Start the remote collector (secure endpoint):
   ```bash
   otelcol-contrib --config otelcol-remote.yaml
   ```

6. In another terminal, start the agent collector (local endpoint):
   ```bash
   otelcol-contrib --config otelcol-agent.yaml
   ```

7. Send telemetry through the agent (no auth required):
   ```bash
   telemetrygen traces --otlp-attributes='recipe="auth"' --otlp-attributes='method="oidc"' \
     --otlp-insecure --traces 5
   ```

8. Send telemetry directly to the secure endpoint:
   ```bash
   telemetrygen traces --otlp-attributes='recipe="auth"' --otlp-attributes='method="oidc-direct"' \
     --otlp-endpoint localhost:5318 --ca-cert ca.pem \
     --otlp-headers="Authorization=Bearer $TOKEN" --traces 5
   ```


## 🔍 Verification

1. Open `http://localhost:3000` to access Grafana
2. Navigate to Explore and select the traces datasource
3. You should see traces with the `recipe="auth"` attribute and the corresponding `method` attribute indicating which authentication method was used
4. Check the collector logs to see authentication success/failure messages

## 🏗️ Architecture

This recipe demonstrates a two-tier architecture:

- **Agent Collector**: Runs close to applications (same host/pod), accepts telemetry without authentication, and forwards to remote collectors
- **Remote Collector**: Runs in a different security zone, requires authentication, and forwards to telemetry backend

This pattern is common in production deployments where:
- Applications send telemetry to local agents without authentication (trusted network)
- Agents authenticate when forwarding to remote collectors (untrusted network)
- Remote collectors require strong authentication for security

## 🔒 Security Considerations

OIDC with Keycloak provides enterprise-grade security features:

- **Token Management**: Supports token refresh, revocation, and short-lived access tokens
- **Enterprise Integration**: Can integrate with LDAP, Active Directory, and other identity providers
- **Audit Logging**: Full audit trail of authentication events
- **Multi-factor Authentication**: Supports 2FA and other strong authentication methods

For production deployments:
1. Always use TLS for authentication credentials (both client certificates and HTTPS)
2. Configure short token lifespans and enable token refresh
3. Monitor authentication failures and token usage patterns
4. Integrate with your existing identity management system
5. Enable audit logging for security compliance

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.123.0
- `telemetrygen` v0.123.0
- Keycloak v26.0
- Grafana LGTM stack (latest)