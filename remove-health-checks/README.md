# 🍜 Recipe: Remove Health Checks

This recipe demonstrates how to efficiently drop health check traces from your telemetry pipeline using tail sampling. Health checks can generate a significant volume of repetitive traces that add little value to observability but consume resources. This recipe shows how to identify and drop 99% of successful health check traces while keeping all other traces intact.

## 🧄 Ingredients

- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector
- The `otelcol.yaml` file from this directory
- An application that generates health check traces (or simulated health check traces)

## 🥣 Preparation

1. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

2. Send some normal application traces
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure --otlp-attributes='recipe="remove-health-checks"' --telemetry-attributes='http.request.method="POST"' --telemetry-attributes='url.path="/api/users"' --telemetry-attributes='http.response.status_code=200'
   ```

3. Send some health check traces to simulate typical health check traffic
   ```terminal
   telemetrygen traces --traces 1000 --otlp-http --otlp-insecure --otlp-attributes='recipe="remove-health-checks"' --telemetry-attributes='http.request.method="GET"' --telemetry-attributes='url.path="/health"' --telemetry-attributes='http.response.status_code=200'
   ```

4. Send additional health check traces with different path patterns
   ```terminal
   telemetrygen traces --traces 1000 --otlp-http --otlp-insecure --otlp-attributes='recipe="remove-health-checks"' --telemetry-attributes='http.request.method="GET"' --telemetry-attributes='url.path="/actuator/health"' --telemetry-attributes='http.response.status_code=200'
   ```

5. Send some failed health check traces (these should still be kept)
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure --otlp-attributes='recipe="remove-health-checks"' --telemetry-attributes='http.request.method="GET"' --telemetry-attributes='url.path="/health"' --telemetry-attributes='http.response.status_code=503'
   ```

6. Check the output file `after-sampling.jsonl` to verify that:
   - All non-health-check traces are present
   - Only about 1% of successful health check traces (GET requests to `/health*` paths with 200 status) are kept
   - Failed health checks (non-200 status) are still present

## 🎯 Key Configuration Details

The tail sampling processor is configured with:
- A drop policy that matches health check patterns:
  - URL paths matching `/health*`, `/*/health*`, or `/actuator/health*`
  - HTTP method GET
  - HTTP status code 200
- Drops 99% of matching traces using probabilistic sampling
- An `always_sample` policy ensures all other traces are kept

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.123.0
- `telemetrygen` v0.123.0