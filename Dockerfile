# Dockerfile
# Use official Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install dependencies
# Copy requirements and install Python packages (including gunicorn)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY app.py .

# Expose Flask default port
EXPOSE 8080

# Optional: set OpenTelemetry environment variables for Odigos
ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://node-collector.odigos-system:4317" \
    OTEL_RESOURCE_ATTRIBUTES="service.name=poc-py-odigos"

# Start the application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
