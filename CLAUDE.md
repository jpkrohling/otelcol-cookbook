# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of OpenTelemetry Collector recipes for various use cases. Each directory represents a standalone recipe demonstrating specific configurations or integrations with the OpenTelemetry Collector.

## Repository Structure

- **Recipe directories**: Each top-level directory (except `sides/` and `ratatouille/`) contains a self-contained recipe
- **`sides/`**: Contains shared resources like LGTM stack configurations
- **`ratatouille/`**: Contains experimental or incomplete recipes lacking documentation
- **Recipe structure**: Each recipe typically contains:
  - `README.md` with 🍜 emoji header following a consistent format
  - `otelcol.yaml` or `otelcol-*.yaml` configuration files
  - Supporting files (JSON configs, policy files, etc.)

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

Each recipe README should follow this pattern:
1. **Title**: `# 🍜 Recipe: <Name>`
2. **Description**: Brief explanation of what the recipe demonstrates
3. **🧄 Ingredients**: Required tools and files
4. **🥣 Preparation**: Step-by-step instructions
5. **🎯 Key Configuration Details** (optional): Important configuration explanations
6. **😋 Executed last time with these versions**: Version information

## Configuration Patterns

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
- **otlp**: Forwards to another collector or backend
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
Most recipes tested with:
- OpenTelemetry Collector Contrib v0.123.0+
- telemetrygen v0.123.0+
- OpenTelemetry Operator v0.125.0+