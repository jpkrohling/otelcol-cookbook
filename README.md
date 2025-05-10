# 🧑🏼‍🍳🍲 OpenTelemetry Collector Cookbook

This repository has a personal collection of OpenTelemetry Collector recipes curated by [@jpkrohling](https://github.com/jpkrohling).

## 📔 Recipes

Each directory in this repository is a recipe and has an appropriate readme file with instructions.

This repository grew organically based on tests that I needed to perform in order to verify a bug report, create an example configuration for a Grafana Labs customer, or prepare for a presentation. As such, quite a few recipes lack good descriptions and running instructions. Those recipes are found under ["ratatouille"](./ratatouille/).

# 🥢 Tools used

- Custom Collector images from [my collection of distributions](https://github.com/jpkrohling/otelcol-distributions). Anywhere a custom image is being used, you can use contrib if you prefer.
- [`telemetrygen`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen#installing) is used a lot in this repository to send telemetry data to our Collector instance
- [`otelcol-contrib`](https://github.com/open-telemetry/opentelemetry-collector-releases/releases) is used as well, both in binary format for local examples, and as container image in examples using Kubernetes
- [`k3d`](https://k3d.io) is used in the Kubernetes recipes, in order to create a local Kubernetes cluster
- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) is used in most Kubernetes recipes. See the setup instructions below
- `kubens` from the [`kubectx`](https://github.com/ahmetb/kubectx) project

## 🍴 OpenTelemetry Operator

To get a working instance of the OpenTelemetry Operator, [follow the official instructions](https://github.com/open-telemetry/opentelemetry-operator?tab=readme-ov-file#getting-started) from the project, but here's a quick summary of what's needed for our purposes:

```terminal
k3d cluster create

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait --for=condition=Available deployments/cert-manager -n cert-manager

kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
kubectl wait --for=condition=Available deployments/opentelemetry-operator-controller-manager -n opentelemetry-operator-system
```

## 🍣 LGTM

For some recipes, we are using Grafana's LGTM stack to visualize data. You can just start the container with the LGTM stack, or install the stack in your Kubernetes cluster. It's not recommended to use this container image in production: either install a proper LGTM stack following the official instructions, or use an observability vendor to manage the backend for you.

### Container

In this example, we are opening only the Grafana and OTel Collector's HTTP port, which is sufficient for our tests.

```terminal
docker run -p 3000:3000 -p 4318:4318 --rm -d grafana/otel-lgtm
```

### Kubernetes

```terminal
kubectl create ns lgtm
kubens lgtm
kubectl apply -f lgtm/lgtm.yaml
kubectl wait --for=condition=Available deployments/lgtm -n lgtm
```

# 🪳 Bugs

Did you find a bug? Is a recipe confusing, or not working at all? Please [open an issue](https://github.com/jpkrohling/otelcol-cookbook/issues/new). Make sure to include:

- the recipe name
- the command you used to run the recipe
- the version of the Collector you are using
- what you expected to see
- what you saw instead
