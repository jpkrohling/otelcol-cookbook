# 🍜 Recipe: Profiling the Collector

When the Collector itself is the thing you need to debug — high CPU, a memory leak, goroutine
growth — turn on its `pprof` extension and pull Go runtime profiles straight from the pod. This
recipe exposes the pprof endpoint on Kubernetes and shows how to reach it; continuous profiling
with Pyroscope is an optional layer on top.

| | |
|---|---|
| **Signals** | (the Collector's own runtime profiles) |
| **Runs on** | Kubernetes |
| **Key components** | pprofextension |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The `otelcol-cr.yaml` and `otelcol-pprof-svc.yaml` from this directory
- `curl` and (optionally) the `go` toolchain to open profiles interactively

## 🥣 Preparation

1. Create and switch to a namespace:
   ```terminal
   kubectl create ns profiling-the-collector
   kubens profiling-the-collector
   ```

2. Deploy the Collector and the service that exposes the pprof port:
   ```terminal
   kubectl apply -f otelcol-cr.yaml
   kubectl apply -f otelcol-pprof-svc.yaml
   ```

3. Port-forward the pprof port and list the available profiles:
   ```terminal
   kubectl port-forward svc/profiling-the-collector-collector-pprof 1777
   curl -s http://localhost:1777/debug/pprof/
   ```
   You'll see `heap`, `goroutine`, `allocs`, `mutex`, `block`, `profile`, `threadcreate`.

4. Pull a profile — e.g. the heap, or open it interactively with the Go tooling:
   ```terminal
   curl -s http://localhost:1777/debug/pprof/heap -o heap.pprof
   go tool pprof -http=: heap.pprof          # interactive flame graph
   curl -s "http://localhost:1777/debug/pprof/goroutine?debug=1" | head -1   # goroutine count
   ```

## 🎯 Key details

- The `pprof` extension serves the standard Go `net/http/pprof` endpoints on `0.0.0.0:1777`.
  It must be listed under `service.extensions` to be active.
- The Operator doesn't expose port 1777 by default, so `otelcol-pprof-svc.yaml` adds a `Service`
  that selects the collector pods and publishes it.
- **Continuous profiling (optional):** to ship these profiles to a backend like Grafana
  Pyroscope, run a scraper such as [Grafana Alloy](https://grafana.com/docs/alloy/) with a
  `pyroscope.scrape` block targeting `…-collector-pprof:1777`, forwarding to your Pyroscope
  endpoint. That part needs your own Pyroscope credentials and is outside this recipe's scope.
- Validation on a live k3d cluster confirmed that the pprof service served all seven profile
  types. A heap profile returned about 16 KB of data, and the goroutine profile reported the live
  goroutine count.

## 😋 Tested with

- OpenTelemetry Operator v0.156.0
- OpenTelemetry Collector Contrib v0.157.0
