#!/bin/bash

# 08-create-launch-template.sh
# Creates an EC2 Launch Template for private application instances.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../../config/environment.conf"
source "$(dirname "$0")/../lib/validation.sh"
source "$(dirname "$0")/../lib/aws.sh"
source "$(dirname "$0")/../lib/compute.sh"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
USER_DATA_FILE="$REPO_ROOT/user-data/app-server.sh"

main() {
  validate_prerequisites

  if [[ ! -f "$USER_DATA_FILE" ]]; then
    log_error "User data file not found: $USER_DATA_FILE"
    exit 1
  fi

  log_info "Retrieving application security group..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"

  APP_SG_ID=$(find_security_group_by_name "$VPC_ID" "$APP_SG_NAME")
  require_id "Security Group" "$APP_SG_NAME" "$APP_SG_ID"
  log_success "Found application security group: $APP_SG_ID"

  log_info "Retrieving latest Amazon Linux 2023 AMI..."
  AMI_ID=$(find_latest_amazon_linux_2023_ami)
  require_id "AMI" "Amazon Linux 2023" "$AMI_ID"
  log_success "Using AMI: $AMI_ID"

  log_info "Ensuring launch template exists..."
  LAUNCH_TEMPLATE_ID=$(ensure_launch_template \
    "$LAUNCH_TEMPLATE_NAME" \
    "$AMI_ID" \
    "$INSTANCE_TYPE" \
    "$APP_SG_ID" \
    "$EC2_INSTANCE_PROFILE_NAME" \
    "$USER_DATA_FILE")

  require_id "Launch Template" "$LAUNCH_TEMPLATE_NAME" "$LAUNCH_TEMPLATE_ID"

  log_success "Launch template configured successfully: $LAUNCH_TEMPLATE_ID"
}

main "$@"