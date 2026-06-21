#!/bin/bash

# 09-create-target-group.sh
# Creates an Application Load Balancer target group.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../../config/environment.conf"
source "$(dirname "$0")/../lib/validation.sh"
source "$(dirname "$0")/../lib/aws.sh"
source "$(dirname "$0")/../lib/load-balancing.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Ensuring target group exists..."
  TARGET_GROUP_ARN=$(ensure_target_group "$TARGET_GROUP_NAME" "$VPC_ID" "HTTP" 80)
  require_id "Target Group" "$TARGET_GROUP_NAME" "$TARGET_GROUP_ARN"

  log_success "Target group configured successfully: $TARGET_GROUP_ARN"
}

main "$@"