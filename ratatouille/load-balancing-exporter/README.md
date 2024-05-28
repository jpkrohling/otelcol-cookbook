This example shows how to get a regular load-balancing done with Kubernetes services. In this demo, we'll have one client instance and initially 3 servers. Then, we increment the number of servers to 10, and watch the metrics. After a couple of minutes, all instances should have a similar number of spans being received.

```console
k3d cluster create
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
kubectl wait --for=condition=Available deployments/cert-manager -n cert-manager

kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
kubectl wait --for=condition=Available deployments/opentelemetry-operator-controller-manager -n opentelemetry-operator-system

kubectl create -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.73.2/bundle.yaml
kubectl wait --for=condition=Available deployments/prometheus-operator -n default

kubectl apply -f cr-load-balancer.yaml
kubectl wait --for=condition=Available deployments/loadbalancer-collector -n observability
kubectl wait --for=condition=Available deployments/backends-collector -n observability

kubectl port-forward -n observability service/prometheus-operated 9090:9090
kubectl port-forward -n observability service/loadbalancer-collector 4317:4317
kubectl port-forward -n observability deployments/grafana 3000:3000

# Add a new Prometheus datasource on Grafana, http://prometheus-operated:9090

telemetrygen traces --otlp-insecure --rate 1000 --duration 30m > telemetrygen.log 2>&1 &
sleep 5m

kubectl patch -n observability otelcol backends -p '{"spec":{"replicas":10}}' --type=merge
sleep 5m

kubectl patch -n observability otelcol backends -p '{"spec":{"replicas":5}}' --type=merge
sleep 5m

kubectl patch -n observability otelcol backends -p '{"spec":{"replicas":0}}' --type=merge
sleep 5m

kubectl patch -n observability otelcol backends -p '{"spec":{"replicas":5}}' --type=merge
sleep 5m
```