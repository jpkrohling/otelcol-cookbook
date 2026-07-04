# 🍜 Recipe: Kubernetes Cluster Telemetry

Beyond the telemetry your apps emit, the cluster itself is a source: the state of pods, nodes, deployments, and the stream of Kubernetes Events. This recipe runs a Collector that scrapes cluster-level metrics with the `k8s_cluster` receiver and turns Kubernetes Events into logs with `k8s_events`.

| | |
|---|---|
| **Signals** | metrics, logs |
| **Runs on** | Kubernetes |
| **Key components** | k8sclusterreceiver, k8seventsreceiver |

## 🧄 Ingredients

- A Kubernetes cluster (e.g. [k3d](https://k3d.io)) with `kubectl`
- cert-manager and the OpenTelemetry Operator installed (see the root [`README.md`](../../README.md))
- The `otelcol-cr.yaml` file from this directory

## 🥣 Preparation

1. Apply the manifest — it creates the namespace, the RBAC the receivers need, and the Collector:
   ```terminal
   kubectl apply -f mains/kubernetes-cluster-telemetry/otelcol-cr.yaml
   ```

2. Wait for the Collector and give `k8s_cluster` one collection interval (15s) to emit:
   ```terminal
   kubectl wait --for=condition=Available deployment/otelcol-k8s-collector -n cluster-telemetry --timeout=120s
   ```

3. Inspect what the cluster reports:
   ```terminal
   # cluster-level metrics: container/pod/node/deployment/daemonset state
   kubectl logs deployment/otelcol-k8s-collector -n cluster-telemetry | grep -oE 'k8s\.[a-z_.]+' | sort -u
   # Kubernetes Events as log records
   kubectl logs deployment/otelcol-k8s-collector -n cluster-telemetry | grep -i LogRecord
   ```
   You'll see metrics like `k8s.deployment.available`, `k8s.container.restarts`, and
   `k8s.daemonset.ready_nodes`, alongside log records for each Kubernetes Event.

## 🎯 Key details

- The two receivers read cluster-wide objects, so the Collector's `ServiceAccount` is bound to a
  `ClusterRole` granting `get`/`list`/`watch` on pods, nodes, workloads, events, and more. Without
  that RBAC the receivers fail with `forbidden` errors.
- `k8s_cluster` is a **singleton** — run exactly one replica (the default `deployment` mode), or
  every replica double-counts the cluster. To shard *scrape* targets across replicas you'd use the
  target allocator instead — see [`target-allocator`](../target-allocator/).
- `k8s_events` emits one log record per Kubernetes Event (the same stream as `kubectl get events`),
  which is how you capture scheduling failures, image pull errors, and OOM kills as telemetry.
- This recipe exports to `debug` so it is self-contained. Point the pipelines at an `otlp_http`
  exporter with `basicauth` to ship to a backend — the secret-handling pattern is in
  [`grafana-cloud-from-kubernetes`](../grafana-cloud-from-kubernetes/).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.155.0
- OpenTelemetry Operator v0.154.0
