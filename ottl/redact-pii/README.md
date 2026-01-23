# Recipe: Redact PII with OTTL

This recipe demonstrates how to use the OpenTelemetry Transformation Language (OTTL) to redact Personally Identifiable Information (PII) from span attributes before they reach your backend.

The transform processor replaces the value of `user.email` with "REDACTED" whenever that attribute exists. This pattern can be extended to redact any sensitive attribute such as phone numbers, addresses, or API keys.

## Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `config.yaml` file from this directory
- The `telemetrygen` tool, or any other application that can send OTLP traces to the collector

## Preparation

1. Start the Collector Contrib binary using the provided configuration
   ```terminal
   otelcol-contrib --config ottl/redact-pii/config.yaml
   ```

2. Send traces containing a `user.email` attribute
   ```terminal
   telemetrygen traces \
     --otlp-insecure \
     --traces 1 \
     --telemetry-attributes 'user.email="jane.doe@example.com"'
   ```

3. Watch the collector's output. You should see in the debug exporter output:
   ```
   Attributes:
        -> user.email: Str(REDACTED)
   ```

## How it works

The OTTL statement uses a conditional `where` clause to only modify spans that have the target attribute:

```ottl
set(attributes["user.email"], "REDACTED") where attributes["user.email"] != nil
```

This ensures that spans without the `user.email` attribute are not modified.

## Extending the recipe

You can add multiple statements to redact different attributes:

```yaml
statements:
  - 'set(attributes["user.email"], "REDACTED") where attributes["user.email"] != nil'
  - 'set(attributes["user.phone"], "REDACTED") where attributes["user.phone"] != nil'
  - 'set(attributes["user.address"], "REDACTED") where attributes["user.address"] != nil'
```

For bulk redaction using patterns, consider `delete_matching_keys` or `replace_pattern`:

```yaml
statements:
  - 'delete_matching_keys(attributes, "(?i).*(password|secret|token).*")'
```

## Executed last time with these versions

- OpenTelemetry Collector Contrib v0.143.1
- telemetrygen v0.143.1
