# 🍜 Recipe: Log Deduplication

Noisy systems often emit the same log line over and over — a connection error retried in a
tight loop, for instance. The `logdedup` processor collapses identical records seen within a
time window into a single record that carries a `log_count` of how many were merged, cutting
volume without losing the signal that something is repeating.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | logdedupprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/log-deduplication/otelcol.yaml
   ```

2. Send a burst of identical error logs that match the dedup conditions (severity `ERROR`,
   `log.type = connection`):
   ```terminal
   telemetrygen logs --logs 20 --otlp-insecure \
     --severity-number 17 --severity-text Error \
     --body "connection refused to db" \
     --otlp-attributes='log.type="connection"'
   ```

3. Watch the Collector's console. After the 5s interval, the `debug` exporter emits **one**
   record instead of twenty, tagged with the merge count:
   ```
        -> log_count: Int(20)
   ```

## 🎯 Key details

- `interval: 5s` is the aggregation window: records are buffered and a deduplicated batch is
  emitted every interval.
- `conditions` scopes which records are eligible (here: error severity or `log.type=connection`).
  Records that don't match — e.g. an `INFO` line with no `log.type` — pass straight through
  untouched.
- `exclude_fields` lists fields ignored when comparing records for equality, so a high-cardinality
  field like `attributes.request_id` doesn't make every record look unique and defeat the dedup.
- To also mask or redact fields on these logs, pair this with a `transform` processor — see
  [`log-redaction`](../log-redaction/).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
