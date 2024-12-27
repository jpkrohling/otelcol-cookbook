kubectl create ns scratchpad
kubens scratchpad

kubectl apply -f otelcol-sampling.yaml
kubectl apply -f otelcol-loadbalancer.yaml

kubectl port-forward svc/otelcol-loadbalancer-collector 4317

telemetrygen traces --duration 30m --rate 500 --otlp-insecure --otlp-attributes='recipe="scratchpad"'

kubectl apply -f otelcol-pprof-svc.yaml

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install pyroscope-ebpf grafana/grafana-agent -f values.yaml --set username=$GRAFANA_CLOUD_PROFILES_USER --set password=$GRAFANA_CLOUD_PROFILES_TOKEN

