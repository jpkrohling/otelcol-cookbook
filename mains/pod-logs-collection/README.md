# 🍜 Recipe: Pod Logs Collection

Everything a container writes to stdout/stderr lands in a file on its node under `/var/log/pods`. This recipe runs the Collector as a DaemonSet so one instance per node tails those files with the `file_log` receiver, parses the container log format, and enriches each record with Kubernetes metadata.

| | |
|---|---|
| **Signals** | logs |
| **Runs on** | Kubernetes |
| **Key components** | filelogreceiver (container parser), DaemonSet |

## 🧄 Ingredients

- A Kubernetes cluster (e.g. [k3d](https://k3d.io)) with `kubectl`
- cert-manager and the OpenTelemetry Operator installed (see the root [`README.md`](../../README.md))
- The `otelcol-cr.yaml` file from this directory

## 🥣 Preparation

1. Deploy the DaemonSet:
   ```terminal
   kubectl apply -f mains/pod-logs-collection/otelcol-cr.yaml
   kubectl rollout status daemonset/pod-logs-collector -n pod-logs --timeout=120s
   ```

2. Generate some log activity (`start_at: end` means only logs written *after* the collector
   started are read):
   ```terminal
   kubectl run logmaker --image=busybox -n pod-logs --restart=Never -- \
     sh -c 'for i in $(seq 1 30); do echo "hello log line $i"; sleep 1; done'
   ```

3. Watch the collector ingest container logs:
   ```terminal
   kubectl logs daemonset/pod-logs-collector -n pod-logs | grep "log records"
   ```
   With `verbosity: detailed` you can see each record carries the Kubernetes metadata the container
   parser derives from the file path — `k8s.pod.name`, `k8s.namespace.name`, `k8s.container.name`.

## 🎯 Key details

- `mode: daemonset` runs one Collector per node; the `/var/log/pods` `hostPath` (mounted read-only)
  gives it access to that node's container log files.
- The `container` operator parses the CRI/containerd log line (timestamp, stream, multi-line
  reassembly) and attaches `k8s.pod.name` / `k8s.namespace.name` / `k8s.container.name` from the
  log file path — no API access or RBAC required.
- The `exclude` pattern drops the collector's **own** logs. Without it, the debug output this
  collector writes to stdout lands back in `/var/log/pods` and gets re-ingested in a runaway loop —
  a classic self-amplification trap for log collectors.
- `start_at: end` skips pre-existing log content so a restart doesn't replay old logs; pair it with
  the `file_storage` extension to persist read offsets across restarts (see
  [`persistent-queue`](../../starters/persistent-queue/) for that extension).
- To ship these logs to a backend, swap `debug` for an `otlp_http` exporter with auth — the
  secret-handling pattern is in [`grafana-cloud-from-kubernetes`](../grafana-cloud-from-kubernetes/).

## 😋 Tested with

- OpenTelemetry Collector Contrib v0.157.0
- OpenTelemetry Operator v0.156.0
