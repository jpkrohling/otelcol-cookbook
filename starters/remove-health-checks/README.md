# 🍜 Recipe: Remove Health Checks

Health checks generate a high volume of repetitive, low-value traces. This recipe uses the
tail sampling processor to drop 99% of *successful* health-check traces (GET requests to
`/health*` paths returning 200) while keeping every other trace — including failed health
checks — intact.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | tailsamplingprocessor, fileexporter |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/remove-health-checks/otelcol.yaml
   ```

2. Send some normal application traces (these are always kept):
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure \
     --telemetry-attributes='http.request.method="POST"' \
     --telemetry-attributes='url.path="/api/users"' \
     --telemetry-attributes='http.response.status_code=200'
   ```

3. Send a burst of successful health-check traces (99% of these are dropped):
   ```terminal
   telemetrygen traces --traces 1000 --otlp-http --otlp-insecure \
     --telemetry-attributes='http.request.method="GET"' \
     --telemetry-attributes='url.path="/health"' \
     --telemetry-attributes='http.response.status_code=200'
   ```

4. Send some *failed* health checks (these are kept — a failing health check is signal):
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure \
     --telemetry-attributes='http.request.method="GET"' \
     --telemetry-attributes='url.path="/health"' \
     --telemetry-attributes='http.response.status_code=503'
   ```

5. Inspect `after-sampling.jsonl`. All `/api/users` traces are present, all `503` health checks
   are present, and only about 1% of the successful `/health` traces remain.

## 🎯 Key details

- The drop policy combines four sub-policies (all must match): a regex on `url.path`
  (`/health*`, `/*/health*`, `/actuator/health*`), `http.request.method == GET`,
  `http.response.status_code == 200`, and a `probabilistic` sub-policy that drops 99% of the
  matches. Failed health checks never match the status sub-policy, so they are kept.
- The trailing `always_sample` policy keeps everything the drop policy did not match.
- Tail sampling buffers each trace until `decision_wait` (2s) elapses, so the processor can see
  all spans of a trace before deciding. Allow a moment after sending before reading the output.
- For a multi-file version of this same pipeline, see
  [`decompose-config`](../decompose-config/).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
