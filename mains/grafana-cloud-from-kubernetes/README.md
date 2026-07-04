# 🍜 Recipe: Grafana Cloud from Kubernetes (Secret Handling)

Send telemetry to Grafana Cloud — or any Basic-auth OTLP/HTTP backend — from a Collector running
in Kubernetes, **without putting credentials in the config**. The credentials live in a `Secret`,
the Operator mounts them as environment variables, and the config reads them via `${env:...}`.
It's the Kubernetes counterpart of [`starters/grafana-cloud`](../../starters/grafana-cloud/).

| | |
|---|---|
| **Signals** | traces, logs, metrics |
| **Runs on** | Kubernetes |
| **Key components** | basicauthextension, `${env:}` expansion, `Secret` + `envFrom` |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The `otelcol-cr.yaml` file from this directory
- A Grafana Cloud (or other OTLP/HTTP) endpoint, a username/instance ID, and an API token
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Create and switch to a namespace:
   ```terminal
   kubectl create ns grafana-cloud-from-kubernetes
   kubens grafana-cloud-from-kubernetes
   ```

2. Put the credentials in a `Secret` — this is the only place they exist in cleartext:
   ```terminal
   kubectl create secret generic grafana-cloud-credentials \
     --from-literal=GRAFANA_CLOUD_USER="$GRAFANA_CLOUD_USER" \
     --from-literal=GRAFANA_CLOUD_TOKEN="$GRAFANA_CLOUD_TOKEN"
   ```

3. Point the `otlp_http` exporter's `endpoint` at your stack, then deploy the Collector:
   ```terminal
   kubectl apply -f otelcol-cr.yaml
   ```

4. Send traces and check Grafana:
   ```terminal
   kubectl port-forward svc/grafana-cloud-from-kubernetes-collector 4317
   telemetrygen traces --traces 2 --otlp-insecure
   ```

## 🎯 Key details

- **`spec.envFrom[].secretRef`** projects every key of the `Secret` into the collector container
  as an environment variable. `${env:GRAFANA_CLOUD_USER}` in the config then resolves to the
  Secret's value at load time — the token never appears in the `OpenTelemetryCollector` resource
  or in the rendered ConfigMap.
- Rotating the token is a `kubectl` edit of the `Secret` plus a pod restart; the recipe manifest
  never changes and is safe to commit to git.
- The `basicauth` extension turns those env values into the `Authorization: Basic ...` header on
  the `otlp_http` exporter's requests.

## 😋 Tested with

Validated on a live k3d cluster against an in-cluster Collector whose OTLP/HTTP receiver required
Basic auth: the `Secret` keys arrived as env vars, `${env:}` resolved them, and the authenticated
export was accepted (6 spans delivered).

- OpenTelemetry Operator v0.154.0
- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
