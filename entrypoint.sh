#!/usr/bin/env bash
set -o errexit

# Force Railway redeploy - 2026-08-24-14-45 - Add static file handling
echo "=== Dalal Platform Startup ==="
export PYTHONPATH=/app:$PYTHONPATH

# Ensure static directory exists
mkdir -p /app/static

# Check if settings.py contains properties app
if [ -f /app/dalal_project/settings.py ]; then
    echo "Settings.py contains 'properties': $(grep -c 'properties' /app/dalal_project/settings.py || echo '0')"
    echo "Settings.py contains 'INSTALLED_APPS': $(grep -c 'INSTALLED_APPS' /app/dalal_project/settings.py || echo '0')"
else
    echo "ERROR: settings.py not found"
fi

# Check if properties app exists
if [ -d /app/properties ]; then
    echo "Properties app exists: True"
else
    echo "ERROR: Properties app not found"
fi

# Check if static files directory has content
if [ "$(ls -A /app/static)" ]; then
    echo "Static files directory has content"
else
    echo "Static files directory is empty, will be populated by collectstatic"
fi

# Run collectstatic to gather static files
echo "Running collectstatic..."
python manage.py collectstatic --noinput --clear
echo "Collectstatic completed"

# Verify static files
echo "Static files after collectstatic:"
ls -la /app/staticfiles/ 2>/dev/null || echo "Staticfiles directory not found"

exec python run_server.py
