# Target Allocator Workload

This directory contains a simple workload application that can be used to test the Target Allocator functionality. The application exposes metrics on port 2112.

## Building the Image

To build the Docker image, run the following command from this directory:

```bash
docker build -t ghcr.io/jpkrohling/otelcol-cookbook/target-allocator/workload .
```

## Image Details

- Base image: Alpine Linux 3.21
- Exposed port: 2112 (metrics)
- Runs as non-root user: `appuser`
- Built using a multi-stage build process with Go 1.23

## Running the Container

To run the container:

```bash
docker run -p 2112:2112 ghcr.io/jpkrohling/otelcol-cookbook/target-allocator/workload
```

The metrics will be available at `http://localhost:2112/metrics`.

## Development

The application is written in Go and uses a multi-stage build process to create a minimal container image. The source code is built in a builder stage using `golang:1.23-alpine` and then copied to the final stage using `alpine:3.21`.
