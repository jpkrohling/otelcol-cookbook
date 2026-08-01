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

4. Compare each server pod's accepted spans — they should be close to equal:
   ```terminal
   for pod in $(kubectl get pods -l app.kubernetes.io/instance=client-side-load-balancing.otelcol-server -o name); do
     kubectl port-forward $pod 18888:8888 >/dev/null & sleep 2
     echo "$pod: $(curl -s localhost:18888/metrics | grep '^otelcol_receiver_accepted_spans')"
     kill %1
   done
   ```
   A representative run distributed 3 pods at **42 / 44 / 40** accepted spans — evenly balanced.

## 🎯 Key details

- `endpoint: dns:///otelcol-server-collector-headless:4317` tells the gRPC client to resolve the
  **headless** service to the full list of pod IPs; `balancer_name: round_robin` then rotates
  requests across them. A normal (non-headless) service would pin to a single backend.
- `max_connection_age: 1m` on the server is essential: gRPC connections are long-lived, so
  without aging them out a client would keep talking to the same pods even after the pool grows.
  When a connection ages out the client re-resolves DNS and picks up new replicas.
- The server pipelines export to `nop` — this recipe is about *where* data lands, observed
  through each Collector's own `otelcol_receiver_accepted_spans` metric, not about the payload.

## 😋 Tested with

- OpenTelemetry Operator v0.156.0
- OpenTelemetry Collector v0.157.0
- `telemetrygen` v0.157.0
