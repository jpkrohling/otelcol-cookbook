# 🍜 Recipe: Log Redaction

Redact sensitive patterns from logs before export using the transform processor. This recipe redacts Brazilian CPF numbers (`###.###.###-##`) from log bodies and phone numbers (`(##) #####-####`) from log attributes, replacing each match with `<redacted>`.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | transformprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/log-redaction/otelcol.yaml
   ```

2. Send a log containing a CPF and a phone number:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "User with CPF 123.456.789-00 logged in" --telemetry-attributes 'phone="(12) 34567-8912"'
   ```

3. Watch the collector output. The log body should read `User with CPF <redacted> logged in` and the `phone` attribute value should be `<redacted>`.

## 🎯 Key details

- `replace_pattern(log.body, ...)` rewrites the matched substring inside the log body.
- `replace_all_patterns(log.attributes, "value", ...)` scans every attribute *value* (not key) for the pattern and rewrites matches.
- Both run in the `log` OTTL context.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
