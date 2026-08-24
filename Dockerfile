# RAILWAY_CACHE_BUST_2026_08_24_15_35 - Force completely new build
# Railway cache bust - use different Python version
FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    DJANGO_SETTINGS_MODULE=dalal_project.settings \
    USE_WEBSOCKETS=false \
    PYTHONPATH=/app \
    RAILWAY_CACHE_BUST=2026_08_24_15_35

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy all application files
COPY dalal_project /app/dalal_project/
COPY properties /app/properties/
COPY templates /app/templates/
COPY manage.py /app/
COPY run_server.py /app/
COPY entrypoint.sh /app/
COPY nixpacks.toml /app/
COPY railway.toml /app/

# Create required directories
RUN mkdir -p /app/static /app/staticfiles /app/logs /app/media /app/locale

# Copy locale if exists
RUN if [ -d locale ]; then cp -r locale/* /app/locale/; fi

# Verify Django installation
RUN python -c "import django; print(f'Django {django.__version__} installed successfully')"

# Run Django commands
RUN python manage.py makemigrations --noinput || echo "Migrations failed"
RUN python manage.py migrate --noinput || echo "Migrations failed"
RUN python manage.py collectstatic --noinput --clear || echo "Collectstatic failed"

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]