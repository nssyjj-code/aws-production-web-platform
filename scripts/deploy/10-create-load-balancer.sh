#!/bin/bash

# 10-create-load-balancer.sh
# Creates an internet-facing Application Load Balancer and HTTP listener.

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
source "$SCRIPT_DIR/../lib/aws.sh"
source "$SCRIPT_DIR/../lib/load-balancing.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Retrieving public subnet IDs..."
  PUBLIC_SUBNET_A_ID=$(find_subnet_by_name "$VPC_ID" "$PUBLIC_SUBNET_A_NAME")
  PUBLIC_SUBNET_B_ID=$(find_subnet_by_name "$VPC_ID" "$PUBLIC_SUBNET_B_NAME")

  require_id "Public Subnet" "$PUBLIC_SUBNET_A_NAME" "$PUBLIC_SUBNET_A_ID"
  require_id "Public Subnet" "$PUBLIC_SUBNET_B_NAME" "$PUBLIC_SUBNET_B_ID"

  log_success "Found public subnets: $PUBLIC_SUBNET_A_ID, $PUBLIC_SUBNET_B_ID"

  log_info "Retrieving ALB security group..."
  ALB_SG_ID=$(find_security_group_by_name "$VPC_ID" "$ALB_SG_NAME")
  require_id "Security Group" "$ALB_SG_NAME" "$ALB_SG_ID"
  log_success "Found ALB security group: $ALB_SG_ID"

  log_info "Retrieving target group..."
  TARGET_GROUP_ARN=$(find_target_group_by_name "$TARGET_GROUP_NAME")
  require_id "Target Group" "$TARGET_GROUP_NAME" "$TARGET_GROUP_ARN"
  log_success "Found target group: $TARGET_GROUP_ARN"

  log_info "Ensuring Application Load Balancer exists..."
  ALB_ARN=$(ensure_load_balancer \
    "$ALB_NAME" \
    "$PUBLIC_SUBNET_A_ID" \
    "$PUBLIC_SUBNET_B_ID" \
    "$ALB_SG_ID")

  require_id "Application Load Balancer" "$ALB_NAME" "$ALB_ARN"

  log_info "Ensuring HTTP listener exists..."
  LISTENER_ARN=$(ensure_http_listener "$ALB_ARN" "$TARGET_GROUP_ARN")
  require_id "HTTP Listener" "$ALB_NAME" "$LISTENER_ARN"

  log_success "Application Load Balancer configured successfully: $ALB_ARN"
}

main "$@"