# 🍜 Recipe: Decompose Complex Configurations

This recipe demonstrates how to decompose a complex OpenTelemetry Collector configuration into multiple files for better readability and maintainability. Large collector configurations can become unwieldy and difficult to manage, especially when they contain complex policies or repeated patterns. This recipe shows how to use the `${file:filename.yaml}` expansion mechanism to split your configuration across multiple files.

This example provides the same functionality as the `remove-health-checks` recipe, but decomposed into multiple files for better organization. The tail sampling policies are extracted into separate files, making each component focused and easier to understand.

## 🧄 Ingredients

- The `telemetrygen` tool, or any other application that is able to send OTLP data to our collector
- The `otelcol.yaml` file from this directory
- The policy files: `policies-all.yaml`, `policy-health-check-drop.yaml`, `policy-sample-all.yaml`

## 🥣 Preparation

1. Run a Collector distribution with the provided configuration file
   ```terminal
   otelcol-contrib --config otelcol.yaml
   ```

2. Send some normal application traces
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure --otlp-attributes='recipe="decompose-config"' --telemetry-attributes='http.request.method="POST"' --telemetry-attributes='url.path="/api/users"' --telemetry-attributes='http.response.status_code=200'
   ```

3. Send some health check traces to simulate typical health check traffic
   ```terminal
   telemetrygen traces --traces 1000 --otlp-http --otlp-insecure --otlp-attributes='recipe="decompose-config"' --telemetry-attributes='http.request.method="GET"' --telemetry-attributes='url.path="/health"' --telemetry-attributes='http.response.status_code=200'
   ```

4. Check the output file `after-sampling.jsonl` to verify that:
   - All non-health-check traces are present
   - Only about 1% of successful health check traces are kept
   - The behavior matches the monolithic configuration

## 🎯 Configuration Structure

The configuration is split into multiple files:

- **`otelcol.yaml`**: Main configuration file containing receivers, exporters, and service pipelines. References external policy files using `${file:policies-all.yaml}`
- **`policies-all.yaml`**: Index file that references individual policy files
- **`policy-health-check-drop.yaml`**: Contains the complex health check dropping logic (37 lines)
- **`policy-sample-all.yaml`**: Contains the default sampling policy (3 lines)

The `${file:...}` expansion happens at configuration load time and supports:
- Relative paths from the main configuration file
- Nested references (files can reference other files)
- Preserved YAML structure and indentation

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.123.0
- `telemetrygen` v0.123.0