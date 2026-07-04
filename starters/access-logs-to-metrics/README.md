# 🍜 Recipe: Access Logs to Metrics

High-volume HTTP access logs are cheap individually but expensive in aggregate — one line
per request, mostly noise. This recipe converts them into a single
`http.server.request.duration` metric, dimensioned by method, status, and a normalized
route, while keeping server-error (5xx) lines as logs for forensic debugging.

| | |
|---|---|
| **Signals** | logs → logs + metrics |
| **Runs on** | local binary |
| **Key components** | transform, signal_to_metrics, forward, filter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/access-logs-to-metrics/otelcol.yaml
   ```

2. Send a batch of successful requests hitting the same route family with different ids:
   ```terminal
   telemetrygen logs --logs 5 --otlp-insecure \
     --telemetry-attributes http.request.method=\"GET\" \
     --telemetry-attributes url.path=\"/api/users/123\" \
     --telemetry-attributes http.response.status_code=200 \
     --telemetry-attributes duration_ms=120
   ```

3. Send a couple of failing requests on the same route family:
   ```terminal
   telemetrygen logs --logs 2 --otlp-insecure \
     --telemetry-attributes http.request.method=\"GET\" \
     --telemetry-attributes url.path=\"/api/users/456\" \
     --telemetry-attributes http.response.status_code=500 \
     --telemetry-attributes duration_ms=900
   ```

4. Watch the Collector's console:
   - the metrics pipeline emits `http.server.request.duration` exponential-histogram
     datapoints for route `/api/users/{id}` — one for `http.response.status_code=200`
     (count 5), another for `http.response.status_code=500` (count 2). The two raw paths
     (`/api/users/123`, `/api/users/456`) collapse into the same `http.route`.
   - the logs pipeline only prints the 2 `500` records; the 5 `200` bodies never appear as
     logs.

## 🎯 Key details

- The `transform` processor derives `http.route` from `url.path`: it strips the query
  string and collapses numeric path segments to `{id}` — this is what bounds the metric's
  cardinality.
- `telemetrygen`'s `--telemetry-attributes` can't send floating-point values, so the recipe
  sends an integer `duration_ms` and casts it in OTTL (`Double(...) / 1000.0`) to the
  seconds value the histogram expects.
- `signal_to_metrics` (the connector, not `count`) is what makes this a *dimensioned*
  metric: HTTP semantic conventions define only `http.server.request.duration` for
  server-side access logs, no separate request counter, because the histogram's own count
  already carries request volume, and filtering it by `http.response.status_code` gives
  the error rate.
- The `forward`/`filter` fan-out mirrors [`logs-to-metrics`](../logs-to-metrics/) and
  [`count-before-sampling`](../count-before-sampling/): one incoming pipeline is split so
  the same records can be both converted to metrics and selectively kept as logs. Here,
  `filter` drops everything below `500`, so only server errors reach `debug/logs` — a
  forensic path alongside the metric.
- `signal_to_metrics` aggregates per `Consume*` call, with no internal flush interval —
  put a `batch` processor upstream of it in production so more records fold into each
  emitted datapoint; this recipe skips it to keep the demo deterministic.
- This recipe supersedes, for the HTTP-access-log use case, the `count`-connector approach
  in [`logs-to-metrics`](../logs-to-metrics/); that recipe now links back here.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
