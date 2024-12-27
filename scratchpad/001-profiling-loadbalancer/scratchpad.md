kubectl create ns scalable-tail-sampling
kubens scalable-tail-sampling

kubectl apply -f otelcol-sampling.yaml
kubectl apply -f otelcol-loadbalancer.yaml

kubectl port-forward svc/otelcol-loadbalancer-collector 4317

telemetrygen traces --rate 200 --duration 24h --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --otlp-attributes='vip="true"'
telemetrygen traces --rate 200 --duration 24h --otlp-insecure --otlp-attributes='recipe="scalable-tail-sampling"' --otlp-attributes='vip="false"'

