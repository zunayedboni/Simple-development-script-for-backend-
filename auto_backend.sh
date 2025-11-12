#!/usr/bin/env python3
import os
import subprocess
import sys
from datetime import datetime

# Configuration
APP_DIR = "/var/www/html/myApp/shopfloor-suite/backend"
GIT_BRANCH = "main"
LOG_FILE = "/var/log/backend_deploy.log"
PHP_BIN = "/usr/bin/php"
SERVICE_TO_RESTART = "php8.3-fpm"  # change if different

def run_cmd(cmd, cwd=None):
    """Run a shell command and return exit code."""
    print(f"→ Running: {cmd}")
    with open(LOG_FILE, "a") as log:
        log.write(f"\n[{datetime.now()}] $ {cmd}\n")
        process = subprocess.Popen(cmd, shell=True, cwd=cwd,
                                   stdout=log, stderr=log)
        process.wait()
        return process.returncode

def main():
    print("🚀 Starting backend deployment...")
    with open(LOG_FILE, "a") as log:
        log.write(f"\n===== DEPLOYMENT START {datetime.now()} =====\n")

    # Step 1: Go to app directory
    if not os.path.isdir(APP_DIR):
        print(f"❌ ERROR: App directory {APP_DIR} not found.")
        sys.exit(1)
 
    # Step 2: Pull latest code
    if run_cmd(f"git fetch origin {GIT_BRANCH}", APP_DIR) != 0:
        print("❌ Git fetch failed.")
        sys.exit(1)
    run_cmd(f"git reset --hard origin/{GIT_BRANCH}", APP_DIR)

    # Step 3: Install composer dependencies
    run_cmd("php8.3 /usr/local/bin/composer update", APP_DIR)

    # Step 4: Run Laravel migrations
    run_cmd(f"php8.3 artisan migrate", APP_DIR)

    # Step 5: Clear and cache Laravel configs
    run_cmd(f"sudo -u www-data php artisan cache:clear", APP_DIR)

    # Step 6: Restart PHP-FPM or queue worker
    run_cmd(f"sudo systemctl restart {SERVICE_TO_RESTART}")

    print("✅ Deployment completed successfully!")
    with open(LOG_FILE, "a") as log:
        log.write(f"===== DEPLOYMENT END {datetime.now()} =====\n")

if __name__ == "__main__":
    main()



