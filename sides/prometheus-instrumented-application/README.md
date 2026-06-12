# 🍜 Recipe: Prometheus Instrumented Application

This recipe provides a simple workload application that exposes Prometheus metrics. It's particularly useful for testing Target Allocator functionality and other Prometheus-related scenarios.

## 🧄 Ingredients

- Docker or a compatible container runtime
- Go 1.23 (for development only)

## 🥣 Preparation

1. Build the Docker image:
   ```terminal
   docker build -t prometheus-instrumented-application .
   ```

2. Run the container:
   ```terminal
   docker run -p 2112:2112 prometheus-instrumented-application
   ```

3. Access the metrics:
   ```terminal
   curl http://localhost:2112/metrics
   ```

4. Send this image to the Kubernetes cluster. For a local `k3d`:
   ```terminal
   docker tag prometheus-instrumented-application:latest k3d-dosedetelemetria:40503/prometheus-instrumented-application:latest
   docker push k3d-dosedetelemetria:40503/prometheus-instrumented-application:latest
   ```

## 🔧 Technical Details

- Base image: Alpine Linux 3.21
- Exposed port: 2112 (metrics endpoint)
- Security: Runs as non-root user `appuser`
- Build process: Multi-stage build with Go 1.23

## 👩‍💻 Development

The application is written in Go and uses a multi-stage build process to create a minimal container image. The source code is built in a builder stage using `golang:1.23-alpine` and then copied to the final stage using `alpine:3.21`.

## 😋 Last Tested Versions

- Go 1.23
- Alpine Linux 3.21
- Docker 24.0.5
