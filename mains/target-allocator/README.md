# 🍜 Recipe: Target Allocator

This recipe demonstrates how to use the OpenTelemetry Operator's Target Allocator to dynamically discover and scrape Prometheus metrics from Kubernetes pods. The Target Allocator works in conjunction with Prometheus Operator's ServiceMonitor and PodMonitor custom resources to automatically manage scrape configurations for your Prometheus-instrumented applications.

| | |
|---|---|
| **Signals** | metrics |
| **Runs on** | Kubernetes |
| **Key components** | targetallocator, prometheusreceiver |

## 🧄 Ingredients

- OpenTelemetry Operator, see the main [`README.md`](../../README.md) for instructions
- A [Prometheus-instrumented application](../../sides/prometheus-instrumented-application/) image available in your Kubernetes cluster as `prometheus-instrumented-application:latest`. Build it and load it into your cluster (example for k3d):
  ```terminal
  docker build -t prometheus-instrumented-application:latest sides/prometheus-instrumented-application
  k3d image import prometheus-instrumented-application:latest -c <your-cluster>
  ```
- The following files from this directory:
  - `role.yaml`: RBAC configuration for the collector
  - `svc.yaml`: `Service` and `ServiceMonitor` for the workload
  - `otelcol-cr.yaml`: OpenTelemetry Collector configuration
  - `workload.yaml`: Sample application exposing Prometheus metrics

## 🥣 Preparation

1. Install Prometheus CRDs for `PodMonitor` and `ServiceMonitor`
   ```terminal
   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.93.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.93.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
   ```

2. Create and switch to a namespace for our recipe
   ```terminal
   kubectl create ns target-allocator-recipe
   kubens target-allocator-recipe
   ```

3. Install the required role and the OTel Collector custom resource
   ```terminal
   kubectl apply -f mains/target-allocator/role.yaml
   kubectl apply -f mains/target-allocator/otelcol-cr.yaml
   ```

4. Create a sample application that exposes Prometheus metrics
   ```terminal
   kubectl apply -f mains/target-allocator/workload.yaml
   ```

5. Install a custom service for our workload and service monitor, telling Target Allocator which pods have Prometheus targets
   ```terminal
   kubectl apply -f mains/target-allocator/svc.yaml
   ```

6. Open your Grafana instance, go to Explore, and select the metrics data source to view the collected metrics

7. Expose the Target Allocator service locally:
   ```terminal
   kubectl port-forward svc/collector-with-ta-targetallocator 8080:80
   ```

8. Visit the [Target Allocator 'targets' endpoint](http://localhost:8080/jobs/serviceMonitor%2Ftarget-allocator-recipe%2Ftarget-allocator-recipe-metrics%2F0/targets) to explore the discovered targets and their Collector assignments

## 😋 Tested with

- OpenTelemetry Operator v0.158.0
- OpenTelemetry Collector Contrib v0.159.0
- Prometheus Operator CRDs v0.93.1
