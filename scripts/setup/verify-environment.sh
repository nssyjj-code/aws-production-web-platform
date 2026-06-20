#!/bin/bash

set -euo pipefail

echo "[INFO] Verifying deployment environment..."

# AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    echo "[ERROR] AWS CLI is not installed."
    exit 1
fi

echo "[SUCCESS] AWS CLI found."

# AWS Credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "[ERROR] AWS credentials are not configured."
    exit 1
fi

echo "[SUCCESS] AWS credentials verified."

# Git
if ! command -v git >/dev/null 2>&1; then
    echo "[ERROR] Git is not installed."
    exit 1
fi

echo "[SUCCESS] Git found."

echo
echo "[SUCCESS] Environment validation complete."