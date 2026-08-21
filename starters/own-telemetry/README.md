# 🍜 Recipe: Own Telemetry

The Collector emits telemetry about itself — how many spans it accepted, how many it
exported, queue sizes, and more. This recipe shows how to explore that internal telemetry
by exporting it over OTLP to an LGTM backend, kept separate from the data flowing through
the pipeline (which goes to the `debug` exporter).

| | |
|---|---|
| **Signals** | traces (pipeline) · metrics (own telemetry) |
| **Runs on** | local binary |
| **Key components** | otlpreceiver, debugexporter, `service::telemetry` |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- Docker, to run the LGTM backend
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start LGTM. Its OTLP/HTTP port receives the Collector's own metrics, while Grafana lets you
   query them:
   ```terminal
   docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm
   ```

2. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/own-telemetry/otelcol.yaml
   ```

3. Send some traces so the Collector has something to report on:
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="own-telemetry"'
   ```

   The `debug` exporter prints the incoming spans to the Collector's console. This is the data
   *passing through* the Collector — not its own telemetry.

4. Open Grafana at `http://localhost:3000`, go to **Explore**, select the Prometheus data source,
   and run this query after the periodic export completes (up to one minute):
   ```promql
   {__name__=~"otelcol_(receiver_accepted|exporter_sent)_spans_total", service_name="otelcol-own-telemetry"}
   ```

   You should see counters reflecting the traffic you just sent:
   ```prometheus
   otelcol_receiver_accepted_spans_total{receiver="otlp",transport="grpc",...} 4
   otelcol_exporter_sent_spans_total{exporter="debug",...} 4
   ```

   Two traces from `telemetrygen` contain four spans in total. The `service_name` filter isolates
   this Collector's telemetry from LGTM's own Collector metrics.

## 🎯 Key details

- Internal metrics are configured under `service::telemetry::metrics`. A `periodic` reader sends
  them directly to the backend with the declarative OTLP exporter, so the Collector does not
  expose a Prometheus scrape endpoint.
- `service::telemetry::resource` assigns a stable `service.name` to the Collector's own telemetry.
  The SDK also adds a unique `service.instance.id`, which distinguishes replicas in a backend.
- `level: detailed` raises the verbosity of the own telemetry so more series are exposed; the
  default level is `normal`.
- The `debug` exporter is used deliberately so there's no confusion between telemetry the
  Collector *processes* and telemetry the Collector *produces about itself*.
- `service::telemetry` can also export the Collector's own traces via OTLP to any backend.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
