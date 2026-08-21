# 🍜 Recipe: Tail Sampling Basics

Keep only the traces worth keeping: errors and slow requests. The tail sampling processor waits
for every span of a trace to arrive before deciding, so — unlike head sampling — you never
accidentally drop an error. Fast, successful traces are discarded to save on storage.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | tailsamplingprocessor |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/tail-sampling-basics/otelcol.yaml
   ```

2. Send fast, successful traces — these are dropped:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 5
   ```

3. Send error traces — these are kept:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 2 --status-code Error
   ```

4. Send slow traces — these are kept:
   ```terminal
   telemetrygen traces --otlp-insecure --traces 2 --span-duration 600ms
   ```

5. Watch the Collector's console. After the 1s `decision_wait`, only the error traces
   (`Status code: Error`) and the slow traces (>500ms) are exported; the fast successful traces
   from step 2 never appear.

## 🎯 Key details

- The two policies are OR'd — a trace is kept if it matches **any** policy:
  - `status_code` keeps any trace with a span whose status is `ERROR`.
  - `latency` keeps any trace with a span slower than `threshold_ms` (500ms).
- `decision_wait` (1s here) is how long the processor buffers a trace so all its spans can
  arrive before the decision; raise it if your traces span more than a second.
- `num_traces` caps how many traces are held in memory at once.
- Add more policies to widen what you keep — e.g. a `string_attribute` policy for specific
  services, or a low-percentage `probabilistic` policy for a baseline sample of everything else.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
