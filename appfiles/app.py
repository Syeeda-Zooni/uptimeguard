import os
import time
import random
from datetime import datetime, timedelta
from flask import Flask, render_template, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# --- Version config -------------------------------------------------
# APP_VERSION and FEATURE_INCIDENTS are baked in at Docker build time (see Dockerfile ARG/ENV).
# v1 = stable (status grid only), v2 = canary (adds incident history timeline).
APP_VERSION = os.environ.get("APP_VERSION", "v1")
FEATURE_INCIDENTS = os.environ.get("FEATURE_INCIDENTS", "false").lower() == "true"
VERSION_COLOR = "#2E7D6B" if APP_VERSION == "v1" else "#C2542B"  # teal for v1, burnt orange for v2

# --- Prometheus metrics ----------------------------------------------
REQUEST_COUNT = Counter(
    "statuspulse_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status", "version"],
)
REQUEST_LATENCY = Histogram(
    "statuspulse_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint", "version"],
)
ERROR_COUNT = Counter(
    "statuspulse_errors_total",
    "Total application errors",
    ["endpoint", "version"],
)

# Mock services being "monitored"
SERVICES = [
    {"name": "API Server", "status": "operational", "uptime": 99.98},
    {"name": "Database", "status": "operational", "uptime": 99.95},
    {"name": "Auth Service", "status": "operational", "uptime": 99.91},
    {"name": "CDN", "status": "operational", "uptime": 99.99},
    {"name": "Payment Gateway", "status": "degraded", "uptime": 99.72},
]

INCIDENTS = [
    {
        "service": "Payment Gateway",
        "title": "Elevated latency on payment processing",
        "status": "Monitoring",
        "started": (datetime.utcnow() - timedelta(hours=2)).strftime("%b %d, %I:%M %p"),
    },
    {
        "service": "Database",
        "title": "Brief connection pool exhaustion",
        "status": "Resolved",
        "started": (datetime.utcnow() - timedelta(days=1, hours=3)).strftime("%b %d, %I:%M %p"),
    },
    {
        "service": "CDN",
        "title": "Scheduled maintenance completed",
        "status": "Resolved",
        "started": (datetime.utcnow() - timedelta(days=3)).strftime("%b %d, %I:%M %p"),
    },
]

STATUS_LABELS = {
    "operational": "Operational",
    "degraded": "Degraded Performance",
    "partial_outage": "Partial Outage",
    "major_outage": "Major Outage",
}


@app.before_request
def start_timer():
    request._start_time = time.time()


@app.after_request
def record_metrics(response):
    latency = time.time() - getattr(request, "_start_time", time.time())
    endpoint = request.path
    REQUEST_LATENCY.labels(endpoint=endpoint, version=APP_VERSION).observe(latency)
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=endpoint,
        http_status=response.status_code,
        version=APP_VERSION,
    ).inc()
    if response.status_code >= 500:
        ERROR_COUNT.labels(endpoint=endpoint, version=APP_VERSION).inc()
    return response


@app.route("/")
def home():
    overall_status = "operational"
    if any(s["status"] != "operational" for s in SERVICES):
        overall_status = "degraded"

    return render_template(
        "index.html",
        version=APP_VERSION,
        color=VERSION_COLOR,
        feature_incidents=FEATURE_INCIDENTS,
        services=SERVICES,
        status_labels=STATUS_LABELS,
        overall_status=overall_status,
    )


@app.route("/incidents")
def incidents():
    return render_template(
        "incidents.html",
        version=APP_VERSION,
        color=VERSION_COLOR,
        feature_incidents=FEATURE_INCIDENTS,
        incidents=INCIDENTS,
    )


# --- Kubernetes / observability endpoints -----------------------------
@app.route("/health")
def health():
    # Liveness probe target: is the process up at all?
    return jsonify(status="ok", version=APP_VERSION), 200


@app.route("/ready")
def ready():
    # Readiness probe target: is the app ready to serve traffic?
    return jsonify(status="ready", version=APP_VERSION), 200


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/chaos")
def chaos():
    # Manual failure injection for demoing the canary rollback in Jenkins.
    # Hit this a few times to spike the error rate on purpose.
    if random.random() < 0.5:
        ERROR_COUNT.labels(endpoint="/chaos", version=APP_VERSION).inc()
        return jsonify(status="error", version=APP_VERSION), 500
    return jsonify(status="ok", version=APP_VERSION), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
