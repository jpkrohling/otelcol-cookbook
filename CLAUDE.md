# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of OpenTelemetry Collector recipes for various use cases. Each directory represents a standalone recipe demonstrating specific configurations or integrations with the OpenTelemetry Collector.

## Repository Structure

Recipes are organized as a menu, by depth of effort (see `MIGRATION.md` for refactoring
status and `docs/superpowers/specs/2026-06-12-cookbook-refactoring-design.md` for the design):

- **`starters/`**: quick, local, single-concept recipes
- **`mains/`**: substantial, often Kubernetes, real-world recipes
- **`desserts/`**: advanced showcases & niceties
- **`sides/`**: shared building blocks reused by other recipes (LGTM stack, sample apps)
- **Recipe structure**: each recipe folder is kebab-case and contains a `README.md`, its
  config (`otelcol.yaml` for local recipes, `otelcol-cr.yaml` for Kubernetes), and any
  supporting files. Config files are always `.yaml` (never `.yml`).

## Common Commands

### Running Local Collector
```bash
# Using contrib binary (most common)
otelcol-contrib --config otelcol.yaml

# For specific recipe
otelcol-contrib --config <recipe-name>/otelcol.yaml
```

### Generating Test Data
```bash
# Send traces
telemetrygen traces --otlp-http --otlp-insecure --otlp-attributes='recipe="<recipe-name>"'

# Send logs
telemetrygen logs --otlp-insecure --body "<log message>"

# Send metrics
telemetrygen metrics --otlp-insecure
```

### Kubernetes Setup
```bash
# Create k3d cluster with registry
k3d registry create dosedetelemetria
k3d cluster create --registry-use k3d-dosedetelemetria:<port> dosedetelemetria

# Install cert-manager and OpenTelemetry Operator
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

# Create namespace and switch context
kubectl create ns <recipe-name>
kubens <recipe-name>
```

### LGTM Stack
```bash
# Docker
docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm

# Kubernetes
kubectl create ns lgtm
kubectl apply -f sides/lgtm/lgtm.yaml
```

### TLS Certificate Generation (for TLS recipes)
```bash
cfssl genkey -initca ca-csr.json | cfssljson -bare ca
cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
```

## Recipe README Structure

Each recipe README follows this contract:
1. **Title**: `# 🍜 Recipe: <Name>`
2. **Description**: one or two sentences on what the recipe demonstrates
3. **Metadata table**: a three-row table with `**Signals**` (traces/metrics/logs),
   `**Runs on**` (local binary / Kubernetes), and `**Key components**`
4. **🧄 Ingredients**: required tools and files
5. **🥣 Preparation**: numbered step-by-step instructions (show the native
   `otelcol-contrib`/`telemetrygen` commands a user runs)
6. **🎯 Key details** (optional — the *only* sanctioned optional section): config explanations
7. **😋 Tested with**: pinned versions as a plain bullet list (no preamble line)

Each recovered recipe must pass a runtime smoke test (local recipes via the collector Docker
image + `telemetrygen`; Kubernetes recipes via a real k3d + Operator deploy) before it is
considered done.

## Configuration Patterns

### Component Naming
Always use the current, non-deprecated component type name; never a deprecated alias, even
though the alias still works. The collector renamed many components to snake_case (v0.149–v0.153),
so prefer e.g. `otlp_grpc` (not the `otlp` exporter alias — the `otlp` *receiver* keeps its name),
`file_log` (not `filelog`), `span_metrics` (not `spanmetrics`), `log_dedup` (not `logdedup`),
`load_balancing` (not `loadbalancing`), `k8s_attributes`, `resource_detection`. When in doubt,
confirm the canonical name and rename status against the `otel-collector` skill or the component's
upstream README before using it.

### File Expansion
The collector supports `${file:filename.yaml}` for decomposing complex configs:
```yaml
processors:
  tail_sampling:
    policies: ${file:policies-all.yaml}
```

### Common Receivers
- **OTLP**: Primary receiver for OpenTelemetry Protocol data
  - HTTP: Port 4318 (insecure), 5318 (secure)
  - gRPC: Port 4317 (insecure), 5317 (secure)

### Common Exporters
- **file**: Writes to local files (`.jsonl` format)
- **otlp_grpc**: Forwards to another collector or backend over OTLP/gRPC (was the `otlp` exporter)
- **otlp_http**: Forwards over OTLP/HTTP (was the `otlphttp` exporter alias, deprecated as of v0.155.0)
- **debug**: Prints to console (formerly logging exporter)

### Testing Patterns
- Use `telemetrygen` with `--otlp-attributes='recipe="<recipe-name>"'` to tag test data
- For health check testing: include attributes like `http.request.method`, `url.path`, `http.response.status_code`
- Output files typically named `after-sampling.jsonl` or similar descriptive names

## Kubernetes Resources
- **OpenTelemetryCollector CRD**: Managed by OpenTelemetry Operator
- **Secrets**: Store credentials with `kubectl create secret generic`
- **Port forwarding**: Use `kubectl port-forward svc/<service-name> 4317` for local access

## Version Compatibility
Recovered recipes are validated against the latest released versions at recovery time, pinned
in each recipe's `😋 Tested with` section. Current pins:
- OpenTelemetry Collector Contrib v0.155.0
- telemetrygen v0.155.0
- OpenTelemetry Operator v0.154.0