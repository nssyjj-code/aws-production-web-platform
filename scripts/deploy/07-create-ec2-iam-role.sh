#!/bin/bash

# 07-create-ec2-iam-role.sh
# Creates the EC2 IAM role and instance profile for SSM-managed instances.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config/environment.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[ERROR] Missing config file: $CONFIG_FILE"
  exit 1
fi

# shellcheck source=../../config/environment.conf
source "$CONFIG_FILE"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/config/environment.conf"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/iam.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TRUST_POLICY_PATH="$REPO_ROOT/policies/ec2-trust-policy.json"

main() {
  validate_prerequisites

  if [[ ! -f "$TRUST_POLICY_PATH" ]]; then
    log_error "Trust policy file not found: $TRUST_POLICY_PATH"
    exit 1
  fi

  log_info "Ensuring EC2 IAM role exists..."
  ROLE_NAME=$(ensure_ec2_role "$EC2_ROLE_NAME" "$TRUST_POLICY_PATH")
  require_id "IAM Role" "$EC2_ROLE_NAME" "$ROLE_NAME"

  log_info "Ensuring SSM policy is attached..."
  ensure_role_policy_attachment "$EC2_ROLE_NAME" "$SSM_MANAGED_POLICY_ARN"

  log_info "Ensuring EC2 instance profile exists..."
  INSTANCE_PROFILE_NAME=$(ensure_instance_profile "$EC2_INSTANCE_PROFILE_NAME")
  require_id "Instance Profile" "$EC2_INSTANCE_PROFILE_NAME" "$INSTANCE_PROFILE_NAME"

  log_info "Ensuring role is added to instance profile..."
  ensure_role_in_instance_profile "$EC2_INSTANCE_PROFILE_NAME" "$EC2_ROLE_NAME"

  log_success "EC2 IAM role and instance profile configured successfully."
}

main "$@"