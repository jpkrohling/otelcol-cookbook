# 🍜 Recipe: Log Cleanup

This recipe demonstrates how to use the OpenTelemetry Collector's transform processor to clean up sensitive information from logs before they are exported. In this example, we'll show how to redact patterns that look like Brazilian CPF numbers (social security numbers) and phone numbers from log messages and attributes.

The solution uses regular expressions to match and redact:
- CPF pattern (###.###.###-##) from log bodies
- Brazilian phone numbers ((##) #####-####) from log attributes

Both patterns are replaced with a "<redacted>" placeholder. This is particularly useful when you need to process logs that might contain sensitive information before they reach your logging backend.

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../README.md) for instructions
- The `otelcol.yaml` file from this directory
- The `telemetrygen` tool, or any other application that is able to send OTLP logs to our collector

## 🥣 Preparation

1. Start the Collector Contrib binary using the provided configuration
   ```terminal
   otelcol-contrib --config log-cleanup/otelcol.yaml
   ```

2. Send some logs containing CPF numbers and phone numbers to the collector
   ```terminal
   telemetrygen logs --otlp-insecure --body "User with CPF 123.456.789-00 logged in" --telemetry-attributes='phone="(12) 34567-8912"'
   ```

3. Watch the collector's output to see the redacted logs. You should see:
   - CPF numbers in log bodies replaced with "<redacted>"
   - Phone numbers in log attributes replaced with "<redacted>"

## 😋 Executed last time with these versions

The most recent execution of this recipe was done with these versions:

- OpenTelemetry Collector Contrib v0.125.0
- `telemetrygen` v0.126.0
