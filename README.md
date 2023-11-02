# OpenTelemetry Collector Recipes by jpkrohling

This repository has a personal collection of OpenTelemetry Collector recipes curated by [@jpkrohling](https://github.com/jpkrohling).

**Note** that only the recipes referenced in the README files were tested. The others are provided as-is, and may not work.

## Recipes

The recipes are organized in the following categories:

* [Simple](recipes/simple/README.md#simple-recipes): simple recipes that can be used as a starting point for more complex scenarios
* [Grafana](recipes/grafana/): recipes to use with Grafana products and projects, including Loki, Tempo, Mimir, and Grafana Cloud
* [Kubernetes](recipes/kubernetes/): recipes to use on Kubernetes, including the Operator
* [Load balancing](recipes/load-balancing/): recipes to use with the load balancing exporter
* [OTTL](recipes/ottl/): recipes that use components featuring OpenTelemetry Transformation Language (OTTL)
* [Routing](recipes/routing/): recipes to use with the routing processor
* [Tail-sampling](recipes/tail-sampling/): recipes to use with the tail-sampling processor

# Pre-requisites

Most of the recipes send data to the Collector using the [`telemetrygen`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/telemetrygen#installing) command-line tool.

Unless otherwise specified, the recipes will work with the contrib distribution of the collector, which can be started like this:

```commandline
otelcol-contrib --config recipes/simple/simplest.yaml
```

# Bugs

Did you find a bug? Is a recipe confusing, or not working at all? Please [open an issue](https://github.com/jpkrohling/otelcol-configs/issues/new). Make sure to include:

- the recipe name
- the command you used to run the recipe
- the version of the Collector you are using
- what you expected to see
- what you saw instead
