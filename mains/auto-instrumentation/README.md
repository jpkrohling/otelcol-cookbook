# 🍜 Recipe: Auto-instrumentation

Add tracing to an application without touching its code. The OpenTelemetry Operator watches for
a pod annotation and injects the language agent (here, Java) plus the right OTLP configuration at
runtime — ideal for apps you can't or don't want to modify, like Keycloak.

| | |
|---|---|
| **Signals** | traces |
| **Runs on** | Kubernetes |
| **Key components** | OpenTelemetry Operator (Instrumentation CR), Java auto-instrumentation |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- The `otelcol-cr.yaml` (Collector + Instrumentation CR) and `keycloak.yaml` from this directory

## 🥣 Preparation

1. Create and switch to a namespace:
   ```terminal
   kubectl create ns auto-instrumentation
   kubens auto-instrumentation
   ```

2. Deploy the Collector and the `Instrumentation` resource:
   ```terminal
   kubectl apply -f otelcol-cr.yaml
   ```

3. Deploy Keycloak — note the `instrumentation.opentelemetry.io/inject-java: "true"` annotation
   in `keycloak.yaml`, which is what triggers injection:
   ```terminal
   kubectl apply -f keycloak.yaml
   kubectl wait --for=condition=Available deployments/keycloak --timeout=240s
   ```

4. Confirm the agent was injected (an init container copies it into the pod):
   ```terminal
   kubectl get pod -l app=keycloak \
     -o jsonpath='{.items[0].spec.initContainers[*].name}'
   # -> opentelemetry-auto-instrumentation-java
   ```

5. Generate some traffic, then watch the Collector — its `debug` exporter prints spans with
   `service.name: Str(keycloak)`:
   ```terminal
   kubectl port-forward svc/keycloak 8080 &
   for i in $(seq 1 30); do curl -s -o /dev/null http://localhost:8080/realms/master; done
   kubectl logs deploy/auto-instrumentation-collector | grep 'service.name: Str(keycloak)'
   ```

## 🎯 Key details

- The `Instrumentation` CR (`my-java`) defines what gets injected: the agent, the OTLP endpoint
  (the Collector's headless service), and any extra env. The pod annotation selects it.
- **Protocol matters**: the modern Java agent defaults to OTLP `http/protobuf`. This recipe sends
  to the gRPC port `4317`, so the CR pins `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` — without it the
  agent posts HTTP to a gRPC port and every export fails with "unexpected end of stream".
- Injection happens at pod admission, so a workload deployed *before* the `Instrumentation` CR
  must be restarted (`kubectl rollout restart`) to pick it up.

## 😋 Tested with

- OpenTelemetry Operator v0.158.0
- OpenTelemetry Collector v0.159.0
- Keycloak 26.7.2
