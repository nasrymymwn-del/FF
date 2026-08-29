#!/usr/bin/env python
"""Railway production entrypoint: migrate, collectstatic, then gunicorn."""
import os
import subprocess
import sys
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# Force disable WebSockets to use Gunicorn instead of Daphne
os.environ['USE_WEBSOCKETS'] = 'false'

# Set up Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dalal_project.settings')

# Add project root to path
project_root = os.path.dirname(os.path.abspath(__file__))
if project_root not in sys.path:
    sys.path.insert(0, project_root)


def run(cmd, allow_fail=False):
    """Run command with proper PYTHONPATH."""
    logger.info(f"Running: {' '.join(str(c) for c in cmd)}")
    env = os.environ.copy()
    env['PYTHONPATH'] = project_root
    try:
        subprocess.run(cmd, check=True, env=env, cwd=project_root)
    except subprocess.CalledProcessError as e:
        if allow_fail:
            logger.warning(f"Command failed (non-fatal): {e}. Continuing.")
        else:
            logger.error(f"Command failed: {e}")
            raise


def main():
    port = os.getenv('PORT', '8080')
    logger.info(f"=== Dalal Platform Startup (port {port}) ===")
    logger.info(f"DEBUG={os.getenv('DEBUG', 'False')}")
    logger.info(f"DJANGO_SETTINGS_MODULE={os.getenv('DJANGO_SETTINGS_MODULE')}")

    # Verify Django and settings
    try:
        import django
        django.setup()
        from django.conf import settings
        
        logger.info(f"Django {django.__version__} loaded successfully")
        logger.info(f"Properties in INSTALLED_APPS: {'properties' in settings.INSTALLED_APPS}")
        
        # Check OAuth availability (without logging secrets)
        google_available = bool(getattr(settings, 'SOCIAL_AUTH_GOOGLE_OAUTH2_KEY', '') and 
                              getattr(settings, 'SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET', ''))
        facebook_available = bool(getattr(settings, 'SOCIAL_AUTH_FACEBOOK_KEY', '') and 
                                getattr(settings, 'SOCIAL_AUTH_FACEBOOK_SECRET', ''))
        
        logger.info(f"Google OAuth: {'enabled' if google_available else 'disabled'}")
        logger.info(f"Facebook OAuth: {'enabled' if facebook_available else 'disabled'}")
        
    except Exception as e:
        logger.error(f"Error loading Django: {e}")
        raise

    # Database migrations
    logger.info("Running database migrations...")
    run([sys.executable, 'manage.py', 'migrate', '--noinput'], allow_fail=True)

    # Static files
    logger.info("Collecting static files...")
    run([sys.executable, 'manage.py', 'collectstatic', '--noinput'], allow_fail=True)

    # Start Gunicorn
    workers = os.getenv('GUNICORN_WORKERS', '2')
    log_level = os.getenv('GUNICORN_LOG_LEVEL', 'info')
    timeout = os.getenv('GUNICORN_TIMEOUT', '120')

    logger.info(f"Starting Gunicorn: workers={workers}, timeout={timeout}, log_level={log_level}")

    os.execvp(
        'gunicorn',
        [
            'gunicorn',
            'dalal_project.wsgi:application',
            '--bind', f'0.0.0.0:{port}',
            '--workers', workers,
            '--timeout', timeout,
            '--log-level', log_level,
            '--access-logfile', '-',
            '--error-logfile', '-',
            '--forwarded-allow-ips', '*',
            '--capture-output',
        ],
    )


if __name__ == '__main__':
    main()
