# 🍜 Recipe: Span Metrics Connector

This recipe demonstrates how to use the OpenTelemetry Collector's span metrics connector to generate metrics from trace data. The span metrics connector automatically creates RED metrics (Request rate, Error rate, Duration) from incoming spans, allowing you to observe your application's performance without explicitly instrumenting it for metrics collection.

The span metrics connector processes traces and generates metrics such as:
- Request throughput (calls per second)
- Request duration histograms  
- Error rates
- Service and operation-level metrics

These generated metrics are then exported to a LGTM (Loki, Grafana, Tempo, Mimir) stack for visualization and monitoring.

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../README.md) for instructions
- The `otelcol.yaml` file from this directory
- The `dashboard.json` file from this directory (pre-built Grafana dashboard)
- A running LGTM container, see the main [`README.md`](../README.md) for setup instructions
- The `telemetrygen` tool, or any other application that can send OTLP traces to the collector

## 🥣 Preparation

1. Start the LGTM container to receive the generated metrics
   ```terminal
   docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm
   ```

2. Start the Collector Contrib binary using the provided configuration
   ```terminal
   otelcol-contrib --config span-metrics-connector/otelcol.yaml
   ```

3. Send some trace data to the collector to generate metrics
   ```terminal
   telemetrygen traces --otlp-insecure --otlp-endpoint localhost:5318 --duration 30s --rate 10
   ```

4. Open Grafana at http://localhost:3000 (admin/admin for credentials)

5. Navigate to Explore and select the Prometheus data source to view the generated span metrics:
   - `traces_span_metrics_calls_total`: Total number of calls/requests
   - `traces_span_metrics_duration_milliseconds_bucket`: Request duration histogram buckets
   - `traces_span_metrics_duration_milliseconds_sum`: Sum of request durations
   - `traces_span_metrics_duration_milliseconds_count`: Count of requests

6. You can create dashboards and alerts based on these automatically generated metrics

7. Import the pre-built dashboard for better visualization (credits to [Devrim Demiroz](https://www.linkedin.com/in/ulasdevrimdemiroz/)):
   - In Grafana, click the "+" icon in the left sidebar and select "Import"
   - Click "Upload JSON file" and select the `dashboard.json` file from this directory
   - Or copy the contents of `dashboard.json` and paste it in the "Import via panel json" text area
   - Click "Load" and then "Import" to add the "Spanmetrics Demo Dashboard"
   - The dashboard will show service-level and operation-level RED metrics with various visualizations

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.126.0
- `telemetrygen` v0.126.0 