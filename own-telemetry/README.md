# 🍜 Recipe: Own telemetry

This recipe shows how to explore the Collector own's telemetry. Note that we are using the `debug` exporter here, so that we don't get confused about what's telemetry processed by the Collector and what's telemetry from the Collector.

## 🧄 Ingredients

- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector 
- The `otelcol.yaml` file from this directory
- A `GRAFANA_CLOUD_USER` environment variable, also known as Grafana Cloud instance ID, found under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- A `GRAFANA_CLOUD_TOKEN` environment variable, which can be generated under the instructions for "OpenTelemetry" on your Grafana Cloud stack.
- The combination of user and password as an HTTP basic auth header
- The endpoint for your stack

## 🥣 Preparation

1. Generate a basic auth HTTP header
   ```terminal
   echo -n "$GRAFANA_CLOUD_USER:$GRAFANA_CLOUD_TOKEN" | base64 -w0
   ```

2. Use the output from the command above as the value for the basic auth header on `otelcol.yaml`

3. Change the `endpoint` parameter for the `otlp` exporter within the `telemetry` node to point to your stack's endpoint, plus the path `/v1/traces`

4. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

5. Send some telemetry to your Collector
   ```terminal
   telemetrygen traces --traces 2 --otlp-insecure --otlp-attributes='recipe="own-telemetry"'
   ```

6. At console where you started the Collector, you should see log entries reporting the lifecycle of the Collector, eventually reaching a log line similar to the following:
   ```
   2024-05-28T14:26:13.135+0200    info    service@v0.101.0/telemetry.go:103       Serving metrics {"address": ":8888", "level": "Normal"}
   2024-05-28T14:26:13.136+0200    info    service@v0.101.0/service.go:169 Starting otelcol-contrib...     {"Version": "0.101.0", "NumCPU": 16} 
   2024-05-28T14:26:13.136+0200    info    service@v0.101.0/service.go:195 Everything is ready. Begin running and processing data.
   ```

7. Open `localhost:8888/metrics` and explore the available metrics there, especially the following ones:
   ```prometheus
   # HELP otelcol_exporter_sent_spans Number of spans successfully sent to destination.
   # TYPE otelcol_exporter_sent_spans counter
   otelcol_exporter_sent_spans{exporter="debug",service_instance_id="890d4346-b65e-4ad9-a071-0ada4fb43143",service_name="otelcol-contrib",service_version="0.101.0"} 4

   # HELP otelcol_receiver_accepted_spans Number of spans successfully pushed into the pipeline.
   # TYPE otelcol_receiver_accepted_spans counter
   otelcol_receiver_accepted_spans{receiver="otlp",service_instance_id="890d4346-b65e-4ad9-a071-0ada4fb43143",service_name="otelcol-contrib",service_version="0.101.0",transport="grpc"} 4
   ```

8. Open your Grafana instance, go to Explore, and select the traces datasource. You should see one trace with three spans, representing the incoming gRPC connection, the receiver operation, and the exporter operation

9. Switch to your metrics datasource, and check that you have metrics like `receiver_accepted_spans_total` and `exporter_sent_spans_total`. It's normal if they take a couple of minutes to show up there.

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.101.0
- `telemetrygen` v0.101.0
