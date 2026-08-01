# 🍜 Recipe: TLS

Encrypt OTLP traffic with TLS. This recipe runs a single Collector that wears both hats: it
accepts data in the clear on one port and forwards it over TLS to a second, TLS-protected
receiver on the same Collector — exercising both the **client** (exporter) and **server**
(receiver) sides of a TLS configuration backed by a self-signed CA.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | otlpreceiver (TLS), otlpexporter (TLS) |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` and the CSR files (`ca-csr.json`, `server-csr.json`, `client-csr.json`)
- [`cfssl`](https://github.com/cloudflare/cfssl), or any tool that can generate TLS certificates
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

Run everything **from inside this directory** — the config references the certificate files by
relative path:

```terminal
cd starters/tls
```

1. Generate the CA, server, and client certificates:
   ```terminal
   cfssl genkey -initca ca-csr.json | cfssljson -bare ca
   cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
   cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
   ```

2. Start the Collector:
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

3. Send traces to the plain (non-TLS) endpoint:
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="tls"'
   ```

4. Watch the Collector's console. The spans arrive on the insecure receiver, travel over the
   encrypted internal hop, and are printed by the `debug` exporter — proof the TLS handshake
   between the exporter and the secure receiver succeeded.

## 🎯 Key details

- The `otlp/secure` **receiver** presents `server.pem` and only accepts TLS connections; the
  `otlp_grpc/secure` **exporter** presents `client.pem` and trusts the CA via `ca_file`. Both sides
  chain to the same `ca.pem`, which is what makes the handshake verify.
- The certificates' SANs (`localhost`, `127.0.0.1`, from the `*-csr.json` files) must cover the
  hostname the exporter dials (`localhost:5317`); a mismatch is the usual cause of handshake
  failures.
- Generated `*.pem` files are runtime artifacts and are git-ignored — never commit private keys.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
- cfssl v1.6.5
