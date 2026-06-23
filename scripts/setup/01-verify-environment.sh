#!/bin/bash

# 01-verify-environment.sh
# Validates required local tools before deployment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

log_info "Verifying local deployment environment..."

required_commands=(
  "aws"
  "git"
  "bash"
  "jq"
)

for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log_error "$command_name is not installed or not available in PATH."
    exit 1
  fi

  log_success "$command_name found."
done

log_info "Verifying AWS credentials..."

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  log_error "AWS credentials are not configured or are invalid."
  echo
  echo "Run:"
  echo
  echo "  aws configure"
  echo
  exit 1
fi

log_success "AWS credentials verified."

log_info "Tool versions:"
log_info "AWS CLI: $(aws --version 2>&1)"
log_info "Git: $(git --version)"
log_info "Bash: ${BASH_VERSION}"

log_success "Environment validation complete."

exit 0