# 🍜 Recipe: Grafana Cloud (Basic Auth from Env)

Forward OTLP telemetry to Grafana Cloud — or any OTLP/HTTP backend that uses HTTP Basic auth.
The point of the recipe is the credential handling: the `basicauth` extension reads the username
and password from environment variables via `${env:...}`, so secrets never live in the config
file.

| | |
|---|---|
| **Signals** | traces, logs, metrics |
| **Runs on** | local binary |
| **Key components** | basicauthextension, otlp_httpexporter, `${env:}` expansion |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- A Grafana Cloud (or other OTLP/HTTP) endpoint, plus a username/instance ID and an API token
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Point the `otlp_http` exporter's `endpoint` at your stack, then export the credentials so the
   config can pick them up — they stay out of the file:
   ```terminal
   export GRAFANA_CLOUD_USER="<your instance id>"
   export GRAFANA_CLOUD_TOKEN="<your api token>"
   ```

2. Start the Collector:
   ```terminal
   otelcol-contrib --config starters/grafana-cloud/otelcol.yaml
   ```

3. Send some traces:
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="grafana-cloud"'
   ```

4. Open Grafana → Explore, pick the traces datasource, and you should see the traces arrive.

## 🎯 Key details

- `${env:GRAFANA_CLOUD_USER}` / `${env:GRAFANA_CLOUD_TOKEN}` are expanded at config-load time, so
  rotating a token is just a new env var — no config edit, and nothing secret is committed. For
  the Kubernetes equivalent that sources these from a `Secret`, see
  [`mains/grafana-cloud-from-kubernetes`](../../mains/grafana-cloud-from-kubernetes/).
- The `basicauth` extension's `client_auth` block turns the username/password into an
  `Authorization: Basic ...` header on every request the `otlp_http` exporter makes.
- The endpoint is just an example. Any OTLP/HTTP backend behind Basic auth works — the same
  extension also has a `server_auth` mode to *require* Basic auth on a receiver.
- Validation used a local Collector whose OTLP/HTTP receiver required Basic auth. Correct
  environment credentials delivered the spans, while a wrong token returned `401 Unauthorized`.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
