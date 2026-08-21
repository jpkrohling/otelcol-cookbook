# 🍜 Recipe: Tenant Routing

A single Collector ingress can serve many tenants and send each one's telemetry to its own pipeline or backend. This recipe uses the `routing` connector to dispatch traces to a per-tenant pipeline based on a `tenant` resource attribute, with a default pipeline for everything that doesn't match.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | local binary |
| **Key components** | routingconnector |

## 🧄 Ingredients

- OpenTelemetry Collector Contrib, see the main [`README.md`](../../README.md) for instructions
- The `otelcol.yaml` file from this directory
- `telemetrygen`, or any tool that can send OTLP traces with a resource attribute

## 🥣 Preparation

1. Start the Collector with the provided configuration:
   ```terminal
   otelcol-contrib --config starters/tenant-routing/otelcol.yaml
   ```

2. Send traces tagged with different tenants (the `--otlp-attributes` flag sets a *resource*
   attribute):
   ```terminal
   telemetrygen traces --otlp-insecure --traces 5 --otlp-attributes tenant=\"acme\"
   telemetrygen traces --otlp-insecure --traces 3 --otlp-attributes tenant=\"ecorp\"
   telemetrygen traces --otlp-insecure --traces 2 --otlp-attributes tenant=\"globex\"
   ```

3. Watch the collector output. Each `debug/<tenant>` exporter only logs its own tenant's spans:
   `acme` → 10 spans, `ecorp` → 6 spans, and `globex` (no matching route) → 4 spans on the
   default `debug/other`.

## 🎯 Key details

- The `routing` connector is wired as the **exporter** of the input pipeline (`traces/in`) and the
  **receiver** of every output pipeline. Each pipeline ID named in `table` or `default_pipelines`
  must exist as a pipeline that lists `routing` as a receiver, or the collector won't start.
- Routes are evaluated **in order** and each piece of telemetry matches **at most one** route.
  To fan out to several pipelines, list them all under one route's `pipelines`. Set `action: move`
  on a route to stop matched data reaching later routes / the default (the default is `copy`).
- `default_pipelines` catches everything that matched no route. **Without it, unmatched telemetry
  is dropped.** Pair it with `error_mode: ignore` so an OTTL evaluation error routes to the
  default instead of dropping the data.
- `context: resource` evaluates once per resource bundle (cheapest). Use `span`/`log`/`datapoint`
  for per-item conditions. For request metadata, use `otelcol.grpc.metadata["x-tenant"][0]`
  with gRPC or `otelcol.client.metadata["x-tenant"][0]` with HTTP; the older `request` context
  is deprecated. These paths route on gRPC metadata or HTTP headers before the telemetry is even
  parsed (gRPC keys are lowercased). Use `condition` for a plain match; use a `statement`
  (`route() where …`) only when you also want to mutate the data in the same pass, e.g.
  `delete_key(attributes, "x-tenant")`.

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.159.0
- `telemetrygen` v0.159.0
