# 🍜 Recipe: Span Metrics Connector

Generate RED metrics (Rate, Errors, Duration) from trace data without instrumenting your app
for metrics. The `spanmetrics` connector consumes spans from the traces pipeline and emits
`calls` and `duration` metrics, broken down by service and operation, into a metrics pipeline.

| | |
|---|---|
| **Signals** | traces → metrics |
| **Runs on** | local binary |
| **Key components** | spanmetricsconnector |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces
- (optional) `dashboard.json` — a pre-built Grafana dashboard for these metrics

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/span-metrics-connector/otelcol.yaml
   ```

2. Send some traces:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 20
   ```

3. After the connector's flush interval (15s), the `debug` exporter prints the generated
   metrics. You'll see two metric families, dimensioned by `service.name` and `span.name`:
   ```
        -> Name: traces.span.metrics.calls
        -> Name: traces.span.metrics.duration
   ```

## 🎯 Key details

- `traces.span.metrics.calls` is a counter (request rate / error rate when split by status);
  `traces.span.metrics.duration` is a histogram (latency). Together they are the RED metrics.
- `metrics_flush_interval` controls how often the connector emits; the default is 60s, lowered
  to 15s here so the demo produces output quickly.
- **Visualize in Grafana**: point the `metrics` pipeline at a Prometheus-compatible backend
  instead of `debug` — e.g. an [LGTM stack](../../sides/lgtm/) via an `otlphttp` exporter — then
  import `dashboard.json`. Over Prometheus the metrics appear as `traces_span_metrics_calls_total`
  and `traces_span_metrics_duration_milliseconds_bucket`.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
