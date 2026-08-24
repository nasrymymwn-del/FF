# Force Railway rebuild - 2026-08-24-15-25 - Complete restructure to bypass cache
# New build approach with different directory structure
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    DJANGO_SETTINGS_MODULE=dalal_project.settings \
    USE_WEBSOCKETS=false \
    PYTHONPATH=/app

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy directories in different order to change cache key
COPY manage.py /app/
COPY dalal_project /app/dalal_project/
COPY properties /app/properties/
COPY templates /app/templates/
COPY run_server.py /app/
COPY entrypoint.sh /app/
COPY nixpacks.toml /app/
COPY railway.toml /app/
COPY railway.json /app/

# Create all required directories
RUN mkdir -p /app/static /app/staticfiles /app/logs /app/media /app/locale

# Copy locale if exists
RUN if [ -d locale ]; then cp -r locale/* /app/locale/; fi

# Verify structure
RUN echo "=== Directory Structure ===" && \
    ls -la /app/ && \
    echo "=== Properties App ===" && \
    ls -la /app/properties/ && \
    echo "=== Settings ===" && \
    ls -la /app/dalal_project/settings.py

# Run Django commands
RUN python manage.py makemigrations --noinput || echo "Migrations failed"
RUN python manage.py migrate --noinput || echo "Migrations failed"
RUN python manage.py collectstatic --noinput --clear || echo "Collectstatic failed"

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]