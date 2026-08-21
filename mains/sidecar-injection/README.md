# 🍜 Recipe: Sidecar Injection

The OpenTelemetry Operator can attach a Collector to a workload automatically: annotate a pod and the Operator injects a `sidecar`-mode Collector into it. The app then sends telemetry to `localhost`, and the sidecar forwards it on — no per-app endpoint wiring or service discovery.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | Kubernetes |
| **Key components** | OpenTelemetry Operator, OpenTelemetryCollector (mode: sidecar) |

## 🧄 Ingredients

- A Kubernetes cluster (e.g. [k3d](https://k3d.io)) with `kubectl`
- cert-manager and the OpenTelemetry Operator installed (see the root [`README.md`](../../README.md))
- The `otelcol-cr.yaml` file from this directory

## 🥣 Preparation

1. Create the namespace and apply the sidecar Collector plus an annotated workload:
   ```terminal
   kubectl create namespace sidecar-injection
   kubectl apply -f mains/sidecar-injection/otelcol-cr.yaml
   ```
   The workload (`my-microservice`) is a `telemetrygen` pod that sends traces to `localhost:4317`.
   Its `sidecar.opentelemetry.io/inject` annotation names the `OpenTelemetryCollector` to inject.

2. Confirm the Operator injected the Collector. On modern Kubernetes it is added as a **native
   sidecar** — an init container with `restartPolicy: Always` — so look under `initContainers`:
   ```terminal
   kubectl get pod my-microservice -n sidecar-injection \
     -o jsonpath='{range .spec.initContainers[*]}{.name}{" "}{end}'
   # otc-container
   ```

3. Watch the injected sidecar receive the app's spans:
   ```terminal
   kubectl logs my-microservice -n sidecar-injection -c otc-container | grep spans
   ```

## 🎯 Key details

- `spec.mode: sidecar` makes the Operator treat this `OpenTelemetryCollector` as a template to
  inject rather than a standalone deployment. It is only injected into pods that opt in.
- The opt-in annotation `sidecar.opentelemetry.io/inject` accepts the name of a sidecar
  `OpenTelemetryCollector` in the same namespace, `"true"` (if exactly one exists), or a
  `namespace/name` reference. It can sit on the pod, the namespace, or the workload (Deployment).
- On Kubernetes 1.28+ the sidecar is injected as a **native sidecar** (an `initContainer` with
  `restartPolicy: Always`), so it starts before the app and is guaranteed to outlive it during
  shutdown. `kubectl get pod` shows it under init containers, not `spec.containers`.
- The app reaches the sidecar over `localhost` (they share the pod's network namespace), so the
  receiver's default `localhost` bind is fine here — no `0.0.0.0` needed, unlike a standalone CR.
- For *language-agnostic auto-instrumentation* of the app itself (rather than just attaching a
  Collector), see [`auto-instrumentation`](../auto-instrumentation/), which uses the same Operator
  webhook with an `Instrumentation` CR.

## 😋 Tested with

- OpenTelemetry Collector v0.159.0
- OpenTelemetry Operator v0.158.0
- `telemetrygen` v0.159.0
