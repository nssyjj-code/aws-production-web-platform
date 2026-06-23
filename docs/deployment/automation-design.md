# Automation Design

## deploy.sh Overview

The deployment script follows a modular function-based design.

Main execution flow:

deploy_network()
        |
        v
deploy_security()
        |
        v
deploy_database()
        |
        v
deploy_compute()


## Error Handling

The script uses:

set -euo pipefail

to enforce:

- immediate failure handling
- undefined variable detection
- pipeline error detection


## Configuration Management

Deployment values are loaded from:

config/environment.conf

This separates environment configuration from deployment logic.