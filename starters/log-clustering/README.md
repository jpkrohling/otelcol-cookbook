# 🍜 Recipe: Log Clustering

Similar log lines often differ only in a few variable tokens — a username, an
IP address, a request ID. The `drain` processor clusters log lines by their
structural shape and derives a template string (e.g.
`"user <*> logged in from <*>"`), attaching it as the `log.record.template`
attribute so downstream processors and backends can group, filter, or count by
pattern instead of by literal message.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | drainprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP logs

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/log-clustering/otelcol.yaml
   ```

2. Send three login-style logs that share the same shape but differ in the
   username and IP address:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "user alice logged in from 10.0.0.1"
   telemetrygen logs --otlp-insecure --logs 1 --body "user bob logged in from 10.0.0.2"
   telemetrygen logs --otlp-insecure --logs 1 --body "user carol logged in from 10.0.0.3"
   ```

3. Send one differently-shaped log line:
   ```terminal
   telemetrygen logs --otlp-insecure --logs 1 --body "connected to 10.0.0.9"
   ```

4. Watch the Collector's console. The first login line forms a brand-new
   cluster, so Drain has nothing yet to generalize against and annotates it
   with its own literal body:
   ```
        -> log.record.template: Str(user alice logged in from 10.0.0.1)
   ```
   The second and third login lines match that cluster and get the merged,
   wildcarded template:
   ```
        -> log.record.template: Str(user <*> logged in from <*>)
   ```
   The fourth line, being a different shape, forms its own new cluster and —
   just like the first login line — is annotated with its own literal body,
   since it is still the only member of that cluster:
   ```
        -> log.record.template: Str(connected to 10.0.0.9)
   ```
   Send more `"connected to <ip>"` lines and that template will merge into
   `connected to <*>` too, following the same pattern as the login lines.

## 🎯 Key details

- Drain builds a parse tree from the token structure of each log line. Lines
  with similar structure are grouped into a cluster, and the template is
  derived by replacing variable tokens with `<*>`. Templates become more
  accurate and stable as more logs matching a pattern arrive.
- This processor **annotates**; it does not filter. Pair it with a `filter`
  processor downstream to act on `log.record.template` — for example, to drop
  known-noisy patterns like health checks or heartbeats.
- For stable templates across restarts or scaled deployments, the processor
  supports `seed_templates`/`seed_logs` (pre-train known patterns at startup),
  `warmup_min_clusters` (suppress annotation until the tree stabilizes), and
  `storage`/`save_interval` (persist the tree via a storage extension). These
  are production concerns not wired up in this minimal recipe — see the
  `drain` processor's own README for details.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
