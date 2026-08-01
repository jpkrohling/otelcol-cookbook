# AGENTS.md

This file provides guidance to AI coding agents working in this repository.

## Starting a task

Before starting any task, fetch `origin` and ensure the worktree is based on the latest
`origin/main`. Start changes from that revision on a focused feature branch. If local changes,
unpushed commits, or worktree state prevent a safe update, do not overwrite, reset, or discard
them. Stop and tell the user what must be reconciled.

Before editing or committing, verify both the working directory and current branch. This matters
when an agent can access multiple repositories or worktrees. Never assume that a command ran in
the intended checkout.

## Project overview

This repository is a collection of OpenTelemetry Collector recipes. Each recipe demonstrates a
specific configuration or integration and must be understandable and reproducible on its own.

There is no unit-test suite. Runtime smoke tests and Collector configuration validation are the
tests for this repository.

## Repository structure

Recipes are organized as a menu, by depth of effort:

- **`starters/`**: quick, local, single-concept recipes
- **`mains/`**: substantial, often Kubernetes-based, real-world recipes
- **`desserts/`**: advanced showcases and optional refinements
- **`sides/`**: shared building blocks reused by recipes, such as the LGTM stack and sample apps
- **Recipe structure**: each recipe folder is kebab-case and contains a `README.md`, its
  configuration (`otelcol.yaml` for local recipes, `otelcol-cr.yaml` for Kubernetes), and any
  supporting files. Configuration files always use `.yaml`, never `.yml`.

The root `README.md` contains a hand-maintained recipe index. Add, rename, or remove its row when
a recipe changes.

## Source-of-truth policy

Collector components evolve quickly. Before adding or changing component configuration, check
the component's upstream README in `opentelemetry-collector` or
`opentelemetry-collector-contrib`. Use current, non-deprecated component type names and verify
stability per signal.

Before a repository-wide version bump, confirm the latest official releases for:

- `open-telemetry/opentelemetry-collector-releases`
- `open-telemetry/opentelemetry-operator`

Update every affected recipe and validate each one. Do not infer an Operator-managed Collector
image version when a manifest does not pin one; verify it with a real deployment or describe the
limitation explicitly.

## Common commands

### Run a local Collector

```bash
otelcol-contrib --config otelcol.yaml
otelcol-contrib --config starters/<recipe-name>/otelcol.yaml
```

### Generate test data

```bash
# Send traces over OTLP/HTTP and attach a resource attribute
telemetrygen traces --otlp-http --otlp-insecure --otlp-attributes='recipe="<recipe-name>"'

# Send logs over OTLP/gRPC
telemetrygen logs --otlp-insecure --body "<log message>"

# Send metrics over OTLP/gRPC
telemetrygen metrics --otlp-insecure
```

`--otlp-attributes` sets resource attributes. Use `--telemetry-attributes` when a recipe needs
span, log-record, or metric data-point attributes that a processor or connector reads from the
telemetry item itself. This distinction must be verified when documenting a `telemetrygen`
command.

### Kubernetes setup

```bash
k3d registry create dosedetelemetria
k3d cluster create --registry-use k3d-dosedetelemetria:<port> dosedetelemetria

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

kubectl create ns <recipe-name>
kubens <recipe-name>
```

### LGTM stack

```bash
docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm

kubectl create ns lgtm
kubectl apply -f sides/lgtm/lgtm.yaml
```

### TLS certificate generation

```bash
cfssl genkey -initca ca-csr.json | cfssljson -bare ca
cfssl gencert -ca ca.pem -ca-key ca-key.pem client-csr.json | cfssljson -bare client
cfssl gencert -ca ca.pem -ca-key ca-key.pem server-csr.json | cfssljson -bare server
```

Never commit generated private keys.

## Recipe README contract

Each recipe README follows this order:

1. **Title**: `# 🍜 Recipe: <Name>`
2. **Description**: one or two sentences describing what the recipe demonstrates
3. **Metadata table**: `**Signals**`, `**Runs on**`, and `**Key components**`
4. **🧄 Ingredients**: required tools and files
5. **🥣 Preparation**: numbered, reproducible steps using native `otelcol-contrib`,
   `telemetrygen`, Docker, or Kubernetes commands
6. **🎯 Key details**: optional configuration explanations; this is the only optional section
7. **😋 Tested with**: pinned versions as a plain bullet list, with no preamble

Keep recipes narrow and self-contained. Use realistic values rather than `foo` or `bar`.
Commands and examples must be directly runnable.

## Configuration conventions

### Component naming

In Collector YAML, always use the current, non-deprecated component type. Deprecated aliases may
still work, but new and updated recipes must not use them. The `Key components` metadata cells use
upstream Go package names such as `filelogreceiver` and `tailsamplingprocessor`; do not confuse
those package names with YAML type strings. Examples of current YAML type strings include:

- `otlp_grpc`, not the deprecated `otlp` exporter alias; the `otlp` receiver keeps its name
- `otlp_http`, not `otlphttp`
- `file_log`, not `filelog`
- `span_metrics`, not `spanmetrics`
- `log_dedup`, not `logdedup`
- `load_balancing`, not `loadbalancing`
- `k8s_attributes`, not `k8sattributes`
- `resource_detection`, not `resourcedetection`

Confirm names and rename status upstream rather than extending this list from memory.

### File expansion

The Collector supports `${file:filename.yaml}` for decomposing complex configurations:

```yaml
processors:
  tail_sampling:
    policies: ${file:policies-all.yaml}
```

### Common endpoints and exporters

- OTLP/HTTP commonly uses port 4318 without TLS and 5318 in these TLS examples.
- OTLP/gRPC commonly uses port 4317 without TLS and 5317 in these TLS examples.
- `file` writes telemetry to files, commonly using a `.jsonl` filename.
- `otlp_grpc` forwards telemetry over OTLP/gRPC.
- `otlp_http` forwards telemetry over OTLP/HTTP.
- `debug` prints telemetry to the console. Use `verbosity: detailed` when a smoke test or README
  expects record bodies, attributes, or metric details in its output.

### Kubernetes resources

- The OpenTelemetry Operator manages `OpenTelemetryCollector` custom resources.
- Store credentials in Kubernetes Secrets, not manifests.
- Use `kubectl port-forward svc/<service-name> 4317` when a local generator needs to reach a
  Collector service.

## Validation requirements

Every new or substantively changed recipe must be validated at the pinned versions before it is
considered complete.

- Local recipes: run the Collector or its official container image, send representative data
  with `telemetrygen` or the documented client, and verify the expected output.
- Kubernetes recipes: deploy to a real k3d cluster with the pinned Operator when behavior depends
  on reconciliation, injection, service generation, or runtime wiring. A config-only validation
  is not a substitute for those behaviors.
- Capture the exact commands and observed result in the pull request description.
- Clean up test containers, clusters, generated certificates, and other runtime artifacts.

If the observed output differs from the README, update the documentation to match verified
behavior. Do not replace observed results with the expected output from a plan.

## Contributions from AI coding agents

AI-authored contributions are welcome. A human contributor must own the pull request, review the
agent's output, and be able to respond to review feedback. Disclose material agent involvement in
the pull request description or with an appropriate `Co-authored-by` trailer.

Agents must meet the same validation and documentation requirements as human contributors. They
must preserve unrelated local changes, keep changes focused, and verify the target branch and
working directory before every commit.

## Commits and pull requests

Use [Conventional Commits](https://www.conventionalcommits.org/) with this format:

```text
<type>(<optional scope>): <short description>
```

Common types are `feat`, `fix`, `docs`, `chore`, and `refactor`. Use the recipe name as the scope
when it makes the change clearer, for example:

```text
feat(log-clustering): add Drain processor recipe
docs(access-logs-to-metrics): clarify telemetrygen attributes
chore: update recipes to Collector v0.157.0
```

Keep each commit and pull request focused. Include a summary, the exact validation performed, and
any limitations or follow-up work in the pull request description.

## Current validated versions

- OpenTelemetry Collector Contrib v0.157.0
- `telemetrygen` v0.157.0
- OpenTelemetry Operator v0.156.0
