# 🍜 Recipe: Blocking Exporter

By default the OpenTelemetry Collector accepts data into an asynchronous sending queue and returns success to the client immediately. This recipe disables the sending queue so the exporter behaves synchronously: each export attempt runs in the request's own goroutine, so the client's call blocks until the export succeeds or fails, and a failure surfaces to the client as an error instead of being buffered for later.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | otlpexporter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/blocking-exporter/otelcol.yaml
   ```

2. Send some traces:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 5
   ```

3. Watch the collector output. Because the queue is disabled and the configured endpoint (`example.com:4317`) is unreachable, the collector logs export failures and retry attempts inline instead of buffering. Point the exporter at a reachable endpoint to see it succeed synchronously.

## 🎯 Key details

- `sending_queue.enabled: false` removes the in-memory queue between the pipeline and the exporter, making export synchronous within the request goroutine.
- `retry_on_failure` is a separate mechanism and remains enabled by default: the collector still retries inline before it finally returns an error to the client.
- Use this when you prefer backpressure over buffering — the producer slows down rather than the collector accumulating unsent data in memory.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
