# 🍜 Recipe: Count Before Sampling

When you tail-sample traces, only a fraction reach your backend — so any count derived *after* sampling undercounts the real traffic. This recipe counts the spans *before* sampling: the `forward` connector fans the full trace stream out to a `count` connector (which turns it into a metric reflecting 100% of the volume) and to a separate pipeline that applies `tail_sampling`.

| | |
|---|---|
| **Signals** | traces → traces + metrics |
| **Runs on** | local binary |
| **Key components** | countconnector, forwardconnector, tailsamplingprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/count-before-sampling/otelcol.yaml
   ```

2. Send 100 traces (2 spans each):
   ```terminal
   telemetrygen traces --otlp-insecure --traces 100
   ```

3. Watch the collector output. The `debug/metrics` exporter emits `trace.span.count` datapoints
   that sum to ~200 — every ingested span is counted. The `debug/traces` exporter only logs
   ~10% of the traces, because the sampling branch kept just `sampling_percentage: 10`. The metric
   reflects the true volume even though most traces were dropped.

## 🎯 Key details

- The `traces` ingest pipeline has **no processors** and exports to both `count` and `forward`.
  This fan-out is what guarantees counting happens against the unsampled stream.
- `forward` is a no-op connector that simply hands telemetry to another pipeline — here, the
  `traces/sampled` pipeline where `tail_sampling` runs. Without it you cannot both count and
  sample the same data, since a pipeline cannot route to two processor sets directly.
- `count` with empty config emits the default `trace.span.count` metric (one span counter).
  Add named metrics with OTTL `conditions` if you want to count only spans matching a predicate.
- Put any volume metric you trust *before* the sampler. The same shape works for log/datapoint
  counts — see [`logs-to-metrics`](../logs-to-metrics/), which counts high-volume log events.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- `telemetrygen` v0.155.0
