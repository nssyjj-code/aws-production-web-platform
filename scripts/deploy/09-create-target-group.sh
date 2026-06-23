#!/bin/bash

# 09-create-target-group.sh
# Creates an Application Load Balancer target group.

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

AWS_REGION="${AWS_REGION:-us-east-1}"
TARGET_GROUP_HEALTH_CHECK_PATH="${TARGET_GROUP_HEALTH_CHECK_PATH:-/}"

export AWS_PAGER=""

# shellcheck source=../lib/logging.sh
source "$ROOT_DIR/scripts/lib/logging.sh"

# shellcheck source=../lib/aws.sh
source "$ROOT_DIR/scripts/lib/aws.sh"

# shellcheck source=../lib/validation.sh
source "$ROOT_DIR/scripts/lib/validation.sh"

# shellcheck source=../lib/load-balancing.sh
source "$ROOT_DIR/scripts/lib/load-balancing.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  local vpc_id
  vpc_id=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$vpc_id"
  log_success "Found VPC: $vpc_id"

  log_info "Ensuring target group exists..."
  local target_group_arn
  target_group_arn=$(ensure_target_group \
    "$TARGET_GROUP_NAME" \
    "$vpc_id" \
    "HTTP" \
    80 \
    "$TARGET_GROUP_HEALTH_CHECK_PATH")

  require_id "Target Group" "$TARGET_GROUP_NAME" "$target_group_arn"

  log_success "Target group configured successfully: $target_group_arn"
}

main "$@"