# 🍜 Recipe: Decompose a Complex Configuration

Large Collector configurations get hard to read once policies grow. The `${file:filename}`
expansion lets you split a config across several files. This recipe is the exact same pipeline
as [`remove-health-checks`](../remove-health-checks/) — drop 99% of successful health-check
traces — but with the tail sampling policies extracted into their own files.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | tailsamplingprocessor, `${file:}` config expansion |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file and its policy files: `policies-all.yaml`,
  `policy-health-check-drop.yaml`, `policy-sample-all.yaml`
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Run the Collector **from inside this directory** — `${file:}` paths resolve relative to the
   working directory, not the config file:
   ```terminal
   cd starters/decompose-config
   otelcol-contrib --config otelcol.yaml
   ```

2. Send some normal traces and a burst of health checks:
   ```terminal
   telemetrygen traces --traces 10 --otlp-http --otlp-insecure \
     --telemetry-attributes='http.request.method="POST"' \
     --telemetry-attributes='url.path="/api/users"' \
     --telemetry-attributes='http.response.status_code=200'

   telemetrygen traces --traces 1000 --otlp-http --otlp-insecure \
     --telemetry-attributes='http.request.method="GET"' \
     --telemetry-attributes='url.path="/health"' \
     --telemetry-attributes='http.response.status_code=200'
   ```

3. Inspect `after-sampling.jsonl`: all `/api/users` traces are present and only about 1% of the
   `/health` traces remain — identical behaviour to the monolithic recipe.

## 🎯 Key details

- `otelcol.yaml` pulls the whole policy list in with `policies: ${file:policies-all.yaml}`.
- `policies-all.yaml` is itself just a list of nested references — files can reference other
  files:
  ```yaml
  - ${file:policy-health-check-drop.yaml}
  - ${file:policy-sample-all.yaml}
  ```
- Each leaf file holds one focused policy, so the drop logic and the catch-all live apart.
- Expansion happens at config load time and preserves YAML structure and indentation. Paths are
  resolved against the **working directory**, which is why step 1 runs the Collector from here.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
