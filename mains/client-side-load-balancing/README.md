# 🍜 Recipe: Client-side Load Balancing

Spread a Collector's exporter traffic evenly across a pool of downstream Collectors — without a
separate load balancer. The trick is two lines on the client (`dns:///` resolution +
`round_robin`) plus a server-side `max_connection_age` that forces clients to periodically
reconnect and re-resolve DNS, so the pool stays balanced as it scales.

| | |
|---|---|
| **Signals** | traces, logs, metrics |
| **Runs on** | Kubernetes |
| **Key components** | otlpexporter (round_robin), otlpreceiver (keepalive) |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The shared [LGTM stack](../../sides/lgtm/) deployed in the `lgtm` namespace
- The `otelcol-client.yaml` and `otelcol-server.yaml` from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Create and switch to a namespace:
   ```terminal
   kubectl create ns client-side-load-balancing
   kubens client-side-load-balancing
   ```

2. Deploy the server pool (3 replicas) and the client:
   ```terminal
   kubectl apply -f otelcol-server.yaml
   kubectl apply -f otelcol-client.yaml
   ```

3. Send a batch of traces to the client. From your machine, port-forward and use `telemetrygen`,
   or run it in-cluster against `otelcol-client-collector:4317`:
   ```terminal
   kubectl port-forward svc/otelcol-client-collector 4317
   telemetrygen traces --traces 600 --rate 200 --otlp-insecure
   ```

4. Port-forward Grafana from the LGTM namespace:
   ```terminal
   kubectl --context <context> -n lgtm port-forward svc/lgtm 3000:3000
   ```

5. Open Grafana at `http://localhost:3000`, go to **Explore**, select the Prometheus data source,
   and compare accepted spans by Collector instance:
   ```promql
   sum by (service_instance_id) (otelcol_receiver_accepted_spans_total{service_name="otelcol-client-side-load-balancing-server"})
   ```
   A representative run distributed the 1,200 spans as **400 / 400 / 400**, evenly balanced.

## 🎯 Key details

- `endpoint: dns:///otelcol-server-collector-headless:4317` tells the gRPC client to resolve the
  **headless** service to the full list of pod IPs; `balancer_name: round_robin` then rotates
  requests across them. A normal (non-headless) service would pin to a single backend.
- `max_connection_age: 1m` on the server is essential: gRPC connections are long-lived, so
  without aging them out a client would keep talking to the same pods even after the pool grows.
  When a connection ages out the client re-resolves DNS and picks up new replicas.
- The server pipelines export to `nop` — this recipe is about *where* data lands, observed
  through each Collector's own `otelcol_receiver_accepted_spans_total` metric, not about the
  payload. Each replica exports its own metrics to LGTM over OTLP and carries a unique
  `service.instance.id` resource attribute.
- The pinned Operator expects `service::telemetry::resource` in the inline map form used by this
  manifest. Its admission webhook does not preserve the newer `resource::attributes` array.

## 😋 Tested with

- OpenTelemetry Operator v0.156.0
- OpenTelemetry Collector v0.157.0
- `telemetrygen` v0.157.0
