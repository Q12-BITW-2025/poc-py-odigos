# Python Proxy Service with Flask, Swagger & Odigos

This repository contains a simple Python proxy service built with Flask and documented via Swagger (Flasgger). It is instrumented with OpenTelemetry and works seamlessly with Odigos for zero-code observability.

## Features

* **Proxy Endpoint**: Forwards HTTP requests (GET, POST, PUT, DELETE, PATCH) to any target URL.
* **Root Redirect**: Visiting `/` will automatically redirect to the Swagger UI at `/apidocs`.
* **Swagger UI**: Interactive API documentation at `/apidocs`.
* **OpenTelemetry Instrumentation**: Auto-traces Flask and `requests` calls.
* **Odigos Integration**: Leverages Odigos Device Plugin and Node/Gateway collectors for telemetry collection.
* **Kubernetes Deployment**: Ready-to-deploy manifest for EKS, with a LoadBalancer service.

## Repository Structure

```text
├── app.py                   # Flask application with Swagger, root redirect, and OpenTelemetry setup
├── requirements.txt         # Python dependencies
├── Dockerfile               # Docker image definition
├── k8s-python-proxy.yaml    # Kubernetes Deployment & Service manifest
└── README.md                # This documentation
```

* Python 3.8+ and pip
* Docker CLI
* AWS CLI configured for ECR (if pushing images)
* Kubernetes CLI (`kubectl`) with access to your EKS cluster
* Helm 3 for installing Odigos into the cluster
* Odigos Helm repository added:

  ```bash
  helm repo add odigos https://odigos-io.github.io/odigos/ --force-update
  ```

## Local Setup

1. **Install Python dependencies**

   ```bash
   pip install -r requirements.txt
   ```

2. **Run the app**

   * For development (no instrumentation wrapper):

     ```bash
     python app.py
     ```
   * With OpenTelemetry instrumentation (ensure OTLP collector at localhost:4317):

     ```bash
     opentelemetry-bootstrap -a install
     opentelemetry-instrument python app.py
     ```

3. **Access**

   * Root redirect: `http://localhost:5000/` → redirects to Swagger UI
   * API proxy: `http://localhost:5000/proxy?url=https://example.com&verb=GET`
   * Swagger UI: `http://localhost:5000/apidocs`

## Docker Build & Push

1. **Build the image**

   ```bash
   docker build -t python-proxy-service:latest .
   ```

2. **Tag & push to ECR**

   ```bash
   aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com
   docker tag python-proxy-service:latest <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/python-proxy-service:latest
   docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/python-proxy-service:latest
   ```

## Deploy to EKS with Odigos

1. **Install Odigos** (if not already installed):

   ```bash
   helm install odigos odigos/odigos --namespace odigos-system --create-namespace
   ```

2. **Apply your proxy service manifest**:

   ```bash
   kubectl apply -f k8s-python-proxy.yaml
   ```

3. **Verify pods**:

   ```bash
   kubectl get pods -n default -l app=python-proxy-service
   ```

4. **Port-forward Odigos UI** (to inspect traces):

   ```bash
   kubectl port-forward svc/odigos-ui -n odigos-system 3456:80
   ```

   Open `http://localhost:3456` in your browser.

5. **Test the proxy**:

   ```bash
   PROXY_URL=$(kubectl get svc/python-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
   curl "http://$PROXY_URL/proxy?url=https://api.ipify.org&verb=GET"
   ```

## Configuration

* **OTEL\_EXPORTER\_OTLP\_ENDPOINT**: Endpoint for OTLP/gRPC exporter (defaults to `localhost:4317`).
* **Instrumentation Resource**: Set `OTEL_RESOURCE_ATTRIBUTES=service.name=<your-service>` to label spans.
* **Replica Count**: Adjust `replicas` in `k8s-python-proxy.yaml` as needed.

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -am 'Add YourFeature'`)
4. Push to branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
