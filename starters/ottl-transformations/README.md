# 🍜 Recipe: OTTL Transformations

A first taste of the OpenTelemetry Transformation Language (OTTL) with the `transform`
processor. It shows two everyday patterns across two signals: normalizing a value (upper-casing
an HTTP method on spans) and removing sensitive data (dropping a `password` attribute from both
spans and logs).

| | |
|---|---|
| **Signals** | traces, logs |
| **Runs on** | local binary |
| **Key components** | transformprocessor (OTTL) |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file and the sample `trace.json` / `logs.json` from this directory
- `curl`, or any tool that can POST JSON over HTTP

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/ottl-transformations/otelcol.yaml
   ```

2. Send the sample trace (its `http.request.method` is the lowercase `get`, and it carries a
   `password` attribute):
   ```terminal
   curl -X POST http://localhost:4318/v1/traces \
     -H "Content-Type: application/json" \
     -d @starters/ottl-transformations/trace.json
   ```

3. Send the sample log (it carries a `password` attribute):
   ```terminal
   curl -X POST http://localhost:4318/v1/logs \
     -H "Content-Type: application/json" \
     -d @starters/ottl-transformations/logs.json
   ```

4. Watch the Collector's console. The `debug` exporter shows:
   - the span's method normalized — `http.request.method: Str(GET)`
   - no `password` attribute on either the span or the log record

## 🎯 Key details

- **Editor vs. converter functions**: lower-case names like `set` and `delete_key` *modify*
  data; capitalized names like `ToUpperCase` *return* a value used as an argument.
- Statements are context-qualified (`span.attributes[...]`, `log.attributes[...]`), the form the
  current OTTL parser expects.
- `set(...) where ... != nil` only touches spans that actually have the attribute, so unrelated
  spans pass through untouched.
- `error_mode: ignore` lets a statement that fails on one record (e.g. a wrong type) be skipped
  rather than dropping the whole batch.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
