# 🍜 Recipe: Own Telemetry

The Collector emits telemetry about itself — how many spans it accepted, how many it
exported, queue sizes, and more. This recipe shows how to explore that internal telemetry
through the Collector's built-in Prometheus metrics endpoint, kept separate from the data
flowing through the pipeline (which goes to the `debug` exporter).

| | |
|---|---|
| **Signals** | traces (pipeline) · metrics (own telemetry) |
| **Runs on** | local binary |
| **Key components** | otlpreceiver, debugexporter, `service::telemetry` |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/own-telemetry/otelcol.yaml
   ```

2. Send some traces so the Collector has something to report on:
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="own-telemetry"'
   ```

   The `debug` exporter prints the incoming spans to the Collector's console. This is the data
   *passing through* the Collector — not its own telemetry.

3. Now look at the Collector's *own* telemetry on its internal metrics endpoint:
   ```terminal
   curl -s localhost:8888/metrics | grep -E '^otelcol_(receiver_accepted_spans|exporter_sent_spans)'
   ```

   You should see counters reflecting the traffic you just sent:
   ```prometheus
   otelcol_receiver_accepted_spans{receiver="otlp",transport="grpc"} 4
   otelcol_exporter_sent_spans{exporter="debug"} 4
   ```

   (Two traces from `telemetrygen` contain four spans in total.) Open `localhost:8888/metrics`
   in a browser to explore everything else the Collector reports about itself.

## 🎯 Key details

- The internal metrics endpoint is configured under `service::telemetry::metrics`. The modern
  declarative form uses a `pull` reader with a `prometheus` exporter; binding `host: 0.0.0.0`
  (instead of the default `localhost`) makes it reachable from outside a container.
- `level: detailed` raises the verbosity of the own telemetry so more series are exposed; the
  default level is `normal`.
- The `debug` exporter is used deliberately so there's no confusion between telemetry the
  Collector *processes* and telemetry the Collector *produces about itself*.
- `service::telemetry` can also export the Collector's own traces and logs (via OTLP) to any
  backend — the same mechanism, pointed at additional readers/exporters.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
