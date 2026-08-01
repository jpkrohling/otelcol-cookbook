# 🍜 Recipe: Loki Receiver with Authentication

The Collector can stand in for Loki's ingestion endpoint: the `loki` receiver accepts Loki's JSON push API and turns each stream into OTLP log records. This recipe puts it behind HTTP basic auth so only authorized clients can push.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | lokireceiver, basicauthextension |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `curl`, to push logs the way a Loki client (Promtail, Grafana Agent) would

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/loki-receiver/otelcol.yaml
   ```

2. Push a log stream with the correct credentials:
   ```terminal
   curl -u admin:supersecret -H 'Content-Type: application/json' \
     -X POST http://localhost:3500/loki/api/v1/push \
     --data '{"streams":[{"stream":{"service_name":"checkout"},"values":[["1700000000000000000","hello from loki push"]]}]}'
   ```
   The push returns `204 No Content`, and the collector's `debug` exporter logs the record with the
   stream's labels promoted to attributes:
   ```
   Body: Str(hello from loki push)
        -> service_name: Str(checkout)
   ```

3. Try again with a wrong password (or none) — the request is rejected with `401 Unauthorized`
   before any data is ingested:
   ```terminal
   curl -i -u admin:wrongpass -X POST http://localhost:3500/loki/api/v1/push --data '{}'
   ```

## 🎯 Key details

- The `loki` receiver exposes Loki's push API at `POST /loki/api/v1/push`; each stream's labels
  become log-record attributes. Add a `grpc:` block under `protocols` to also accept the gRPC push.
- `auth.authenticator: basicauth` wires the receiver to the `basicauth` extension, which checks
  credentials against its `htpasswd` list. The inline form takes `user:password` (or `user:<hash>`
  for bcrypt/apr1); load it from a file in production rather than inlining the secret.
- This is the inbound counterpart to client-side basic auth — see [`grafana-cloud`](../grafana-cloud/),
  which sends through `basicauth` `client_auth` instead of validating it on a receiver.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
