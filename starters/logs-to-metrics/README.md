# 🍜 Recipe: Logs to Metrics

High-volume, low-information log lines — "http call made to route ..." emitted on every request
— are often better kept as a *count* than stored individually. This recipe splits an incoming
log stream in two: ordinary logs pass through untouched, while the noisy common events are
counted into a metric and discarded.

| | |
|---|---|
| **Signals** | logs → logs + metrics |
| **Runs on** | local binary |
| **Key components** | filterprocessor, countconnector, forwardconnector |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/logs-to-metrics/otelcol.yaml
   ```

2. Send a few "common event" logs (these get counted, not stored):
   ```terminal
   telemetrygen logs --logs 3 --otlp-insecure --body "http call made to route /api/users"
   ```

3. Send some ordinary logs (these are kept as logs):
   ```terminal
   telemetrygen logs --logs 2 --otlp-insecure --body "user logged in successfully"
   ```

4. Watch the Collector's console:
   - the metrics pipeline emits `log.record.count` with value `3` — the common events
   - the logs pipeline emits only the 2 ordinary records; the common-event bodies never appear

## 🎯 Key details

- The `forward` connector fans the single incoming logs pipeline out to two downstream
  pipelines so the same records can be processed two different ways.
- The `filter` processor **drops** the records its conditions match. The two filters are
  mirror images: `remove-common-events` drops the common ones (keeping the rest as logs),
  `retain-common-events` drops everything *but* the common ones (feeding them to the counter).
- The `count` connector turns the log records it receives into a `log.record.count` metric —
  the data changes signal type from logs to metrics.
- Conditions are context-qualified (`log.body`), the form the current OTTL parser expects.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
