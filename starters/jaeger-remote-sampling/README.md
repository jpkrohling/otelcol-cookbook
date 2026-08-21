# 🍜 Recipe: Jaeger Remote Sampling

Jaeger-compatible SDKs can ask a central service which sampling strategy to use instead of hard-coding it per service. This recipe runs the Collector's `jaegerremotesampling` extension as that central service, serving per-service strategies from a local JSON file over Jaeger's remote-sampling HTTP API — editable at runtime without a restart.

| | |
|---|---|
| **Signals** | traces (sampling control plane) |
| **Runs on** | local binary |
| **Key components** | jaegerremotesamplingextension |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` and `strategies.json` files from this directory
- `curl`, to query the sampling endpoint the way an SDK would

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/jaeger-remote-sampling/otelcol.yaml
   ```
   Run the command from the repository root so the relative path to `strategies.json` resolves.

2. Ask for a service that has its own strategy:
   ```terminal
   curl 'http://localhost:5778/sampling?service=checkout'
   ```
   ```json
   {"probabilisticSampling":{"samplingRate":0.5}}
   ```

3. A rate-limiting service and an unknown one (which falls back to the default):
   ```terminal
   curl 'http://localhost:5778/sampling?service=payments'
   # {"strategyType":1,"rateLimitingSampling":{"maxTracesPerSecond":2}}
   curl 'http://localhost:5778/sampling?service=unknown-svc'
   # {"probabilisticSampling":{"samplingRate":0.1}}
   ```

4. Edit a `param` in `strategies.json` and re-run the `checkout` query after a few seconds — the
   new value is served without restarting the Collector, because `reload_interval` re-reads the file.

## 🎯 Key details

- The HTTP server speaks Jaeger's remote-sampling API at `GET /sampling?service=<name>`; point an
  SDK's remote sampler (e.g. `OTEL_TRACES_SAMPLER=jaeger_remote`) at `http://<host>:5778`.
- `strategies.json` has `service_strategies` (per-service `probabilistic` rate or `ratelimiting`
  traces/sec, with optional per-`operation` overrides) and a `default_strategy` fallback.
- `source.file` can be a local path or an HTTP(S) URL; `source.remote.endpoint` instead proxies
  strategies from an upstream Jaeger collector over gRPC. This recipe uses the file source so it
  is self-contained.
- The extension also exposes a gRPC sampling endpoint (default `:14250`) for SDKs that use the
  gRPC protocol; add a `grpc:` block to enable it.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
