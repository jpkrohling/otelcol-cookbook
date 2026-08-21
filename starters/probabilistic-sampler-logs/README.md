# 🍜 Recipe: Probabilistic Sampling for Logs

The probabilistic sampler is most often used on traces, where a traceID gives every span in a
trace a shared key for a consistent keep/drop decision. Plain system logs have no traceID. This
recipe hashes the log **body** with OTTL's `FNV` function to produce a per-record key, then
feeds that to the probabilistic sampler so it keeps a stable ~10% of records.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | local binary |
| **Key components** | filelogreceiver, transformprocessor (FNV), probabilisticsamplerprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- Docker, to run the LGTM backend
- The `otelcol.yaml` file and the sample `dnf.log.1` log file from this directory

## 🥣 Preparation

1. Start LGTM so the Collector can export its own metrics over OTLP:
   ```terminal
   docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm
   ```

2. Run the Collector **from inside this directory** — the `file_log` receiver's `include` path
   is relative to the working directory:
   ```terminal
   cd starters/probabilistic-sampler-logs
   otelcol-contrib --config otelcol.yaml
   ```

   The receiver reads `dnf.log.1` from the beginning; no other input is needed.

3. Open Grafana at `http://localhost:3000`, go to **Explore**, select the Prometheus data source,
   and query how many records were kept versus dropped after the periodic export completes:
   ```promql
   otelcol_processor_probabilistic_sampler_count_logs_sampled_total{service_name="otelcol-probabilistic-sampler-logs"}
   ```

   You should see roughly a 1:9 split — about 10% kept:
   ```prometheus
   otelcol_processor_probabilistic_sampler_count_logs_sampled_total{policy="body.hash",sampled="false",...} 11038
   otelcol_processor_probabilistic_sampler_count_logs_sampled_total{policy="body.hash",sampled="true",...} 1247
   ```

## 🎯 Key details

- The `transform` processor sets `log.attributes["body.hash"]` to `FNV(log.body)`, giving each
  record a deterministic numeric key derived from its content.
- The sampler reads that key via `attribute_source: record` + `from_attribute: body.hash`, so
  identical messages always share a decision; `hash_seed: 22` makes runs reproducible.
- Because the key is the body, this samples *by message content*. If your logs carry a traceID
  or another per-transaction attribute, point `from_attribute` at that instead to keep all logs
  for the sampled transactions.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
