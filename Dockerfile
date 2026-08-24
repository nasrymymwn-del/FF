# Force Railway rebuild - 2026-08-24-15-00 - Complete rebuild with different structure
# Railway cache bust - new approach
FROM python:3.12-slim-bookworm AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

COPY dalal_project /app/dalal_project/
COPY properties /app/properties/
COPY templates /app/templates/
COPY manage.py /app/
COPY run_server.py /app/
COPY entrypoint.sh /app/
COPY nixpacks.toml /app/
COPY railway.toml /app/
COPY railway.json /app/

# Create static directory
RUN mkdir -p /app/static

# Copy locale directory if it exists
RUN if [ -d locale ]; then cp -r locale /app/locale/; else mkdir -p /app/locale; fi

RUN mkdir -p /app/logs /app/media /app/staticfiles

# Final stage
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    DJANGO_SETTINGS_MODULE=dalal_project.settings \
    USE_WEBSOCKETS=false \
    PYTHONPATH=/app

WORKDIR /app

COPY --from=builder /app /app

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]