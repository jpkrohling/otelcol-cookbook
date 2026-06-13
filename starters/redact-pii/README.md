# 🍜 Recipe: Redact PII with OTTL

Redact Personally Identifiable Information (PII) from span attributes before it reaches your
backend. The `transform` processor uses the OpenTelemetry Transformation Language (OTTL) to
replace the value of `user.email` with `REDACTED` whenever that attribute is present.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | transformprocessor (OTTL) |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/redact-pii/otelcol.yaml
   ```

2. Send a trace carrying a `user.email` attribute:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 1 \
     --telemetry-attributes 'user.email="jane.doe@example.com"'
   ```

3. Watch the Collector's console. The `debug` exporter shows the attribute redacted:
   ```
        -> user.email: Str(REDACTED)
   ```

## 🎯 Key details

- The statement is context-qualified (`span.attributes[...]`), the form the current OTTL
  parser expects — the older unqualified `attributes[...]` form still works but logs a
  deprecation nudge.
- The `where ... != nil` guard means spans without `user.email` are left untouched.
- Extend the pattern by adding more statements, one per attribute:
  ```yaml
  trace_statements:
    - set(span.attributes["user.email"], "REDACTED") where span.attributes["user.email"] != nil
    - set(span.attributes["user.phone"], "REDACTED") where span.attributes["user.phone"] != nil
  ```
- For bulk redaction by key pattern, use `delete_matching_keys`:
  ```yaml
  trace_statements:
    - delete_matching_keys(span.attributes, "(?i).*(password|secret|token).*")
  ```

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
