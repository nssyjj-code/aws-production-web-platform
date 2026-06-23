#!/bin/bash

# 11-create-auto-scaling-group.sh
# Creates an Auto Scaling Group for private application instances.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../config/environment.conf"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/aws.sh"
source "$SCRIPT_DIR/../lib/load-balancing.sh"
source "$SCRIPT_DIR/../lib/autoscaling.sh"
source "$SCRIPT_DIR/../lib/autoscaling.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Retrieving private application subnet IDs..."
  PRIVATE_APP_SUBNET_A_ID=$(find_subnet_by_name "$VPC_ID" "$PRIVATE_APP_SUBNET_A_NAME")
  PRIVATE_APP_SUBNET_B_ID=$(find_subnet_by_name "$VPC_ID" "$PRIVATE_APP_SUBNET_B_NAME")

  require_id "Private App Subnet" "$PRIVATE_APP_SUBNET_A_NAME" "$PRIVATE_APP_SUBNET_A_ID"
  require_id "Private App Subnet" "$PRIVATE_APP_SUBNET_B_NAME" "$PRIVATE_APP_SUBNET_B_ID"

  log_success "Found private app subnets: $PRIVATE_APP_SUBNET_A_ID, $PRIVATE_APP_SUBNET_B_ID"

  log_info "Retrieving target group..."
  TARGET_GROUP_ARN=$(find_target_group_by_name "$TARGET_GROUP_NAME")
  require_id "Target Group" "$TARGET_GROUP_NAME" "$TARGET_GROUP_ARN"
  log_success "Found target group: $TARGET_GROUP_ARN"

  log_info "Retrieving launch template..."
  LAUNCH_TEMPLATE_ID=$(find_launch_template_by_name "$LAUNCH_TEMPLATE_NAME")
  require_id "Launch Template" "$LAUNCH_TEMPLATE_NAME" "$LAUNCH_TEMPLATE_ID"
  log_success "Found launch template: $LAUNCH_TEMPLATE_ID"

  log_info "Ensuring Auto Scaling Group exists..."
  ASG_RESULT=$(ensure_auto_scaling_group \
    "$ASG_NAME" \
    "$LAUNCH_TEMPLATE_NAME" \
    "$PRIVATE_APP_SUBNET_A_ID" \
    "$PRIVATE_APP_SUBNET_B_ID" \
    "$TARGET_GROUP_ARN")

  require_id "Auto Scaling Group" "$ASG_NAME" "$ASG_RESULT"

  log_success "Auto Scaling Group configured successfully: $ASG_NAME"
}

main "$@"