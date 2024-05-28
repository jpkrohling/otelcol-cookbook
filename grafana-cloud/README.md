# 🍜 Recipe: Grafana Cloud

This recipe shows how to send telemetry data to Grafana Cloud with the OpenTelemetry Collector. The recommended way to send data for most use-cases is via the OTLP endpoint, given that the Collector already has an internal representation on that format. It's also better to send OTLP Logs via the OTLP endpoint to Grafana Cloud Logs, as it would appropriately place some values, such as the trace ID and span ID, on its new metadata storage, which isn't part of the message body or index.

## 🧄 Ingredients

- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The endpoint for your stack

## 🥣 Preparation

1. Change the `endpoint` parameter for the `otlphttp` exporter to point to your stack's endpoint

2. Export the environment variables `GRAFANA_CLOUD_USER` and `GRAFANA_CLOUD_TOKEN`

3. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

4. Send some telemetry to your Collector
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="grafana-cloud"'
   ```

5. Open your Grafana instance, go to Explore, and select the appropriate datasource, such as "...-traces". If used the command above, click "Search" and you should see two traces listed, each with two spans.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
