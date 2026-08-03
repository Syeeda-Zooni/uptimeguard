FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Build-time flags: set these differently for the stable vs canary image.
#   Stable (v1): --build-arg APP_VERSION=v1 --build-arg FEATURE_INCIDENTS=false
#   Canary (v2): --build-arg APP_VERSION=v2 --build-arg FEATURE_INCIDENTS=true
ARG APP_VERSION=v1
ARG FEATURE_INCIDENTS=false
ENV APP_VERSION=${APP_VERSION}
ENV FEATURE_INCIDENTS=${FEATURE_INCIDENTS}

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
