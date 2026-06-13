# 🍜 Recipe: Scalable Tail Sampling

Tail sampling needs every span of a trace on the *same* Collector instance, because the decision
is made after buffering the whole trace in memory. That makes it hard to scale — so this recipe
splits the work into two layers: a load-balancing layer that consistently routes spans by trace
ID, and a sampling layer that can have as many replicas as you need.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | Kubernetes |
| **Key components** | loadbalancingexporter (routing_key: traceID), tailsamplingprocessor |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The `otelcol-loadbalancer.yaml` and `otelcol-sampling.yaml` from this directory
- (optional) `otelcol-sampling-alt.yaml` — an alternative policy to contrast behaviour
- `telemetrygen`, or any tool that can send OTLP traces

## 🥣 Preparation

1. Create and switch to a namespace:
   ```terminal
   kubectl create ns scalable-tail-sampling
   kubens scalable-tail-sampling
   ```

2. Deploy the sampling layer first, then the load balancer (so its DNS resolves immediately):
   ```terminal
   kubectl apply -f otelcol-sampling.yaml
   kubectl apply -f otelcol-loadbalancer.yaml
   ```

3. Send VIP traces — all of these should be kept:
   ```terminal
   kubectl port-forward svc/otelcol-loadbalancer-collector 4317
   telemetrygen traces --traces 500 --otlp-insecure --telemetry-attributes='vip="true"'
   ```

4. Send non-VIP traces — only about 10% of these should be kept:
   ```terminal
   telemetrygen traces --traces 500 --otlp-insecure --telemetry-attributes='vip="false"'
   ```

5. Compare the sampling decisions on the sampling pods' metrics endpoints:
   ```terminal
   for pod in $(kubectl get pods -l app.kubernetes.io/instance=scalable-tail-sampling.otelcol-sampling -o name); do
     kubectl port-forward $pod 18888:8888 >/dev/null & sleep 2
     curl -s localhost:18888/metrics | grep tail_sampling_count_traces_sampled
     kill %1
   done
   ```
   A representative run showed the `vip` policy sampling ~100% of VIP traces while the
   `only-10-percent` policy kept ~11% of the rest (23 of 205) — and both sampling pods received
   traffic, confirming the trace-ID routing spread load across the layer.

## 🎯 Key details

- The load balancer's `routing_key: traceID` is what makes this correct: every span of a trace
  hashes to the same backend, so a sampler always sees the complete trace.
- `resolver.dns.hostname` points at the sampling layer's **headless** service, so the exporter
  learns every pod IP and can route to each one.
- The sampling policies are OR'd: `vip` keeps all VIP traces, `only-10-percent` keeps a 10%
  baseline of everything else. Swap in `otelcol-sampling-alt.yaml` (a single AND policy) to keep
  only 10% *of the VIP* traces instead — same layers, different emphasis.
- Both layers discard data (`nop`) and are observed purely through
  `otelcol_processor_tail_sampling_*` metrics — this recipe is about the routing/sampling
  behaviour, not the payload.

## 😋 Tested with

- OpenTelemetry Operator v0.153.0
- OpenTelemetry Collector Contrib v0.154.0
- `telemetrygen` v0.154.0
