#!/bin/bash

# 13-create-aurora-cluster.sh
# Creates a private Aurora MySQL cluster.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../../config/environment.conf"
source "$(dirname "$0")/../lib/validation.sh"
source "$(dirname "$0")/../lib/aws.sh"
source "$(dirname "$0")/../lib/database.sh"

main() {
  validate_prerequisites

  if [[ -z "${DB_MASTER_USERNAME:-}" || -z "${DB_MASTER_PASSWORD:-}" ]]; then
    log_error "DB_MASTER_USERNAME and DB_MASTER_PASSWORD must be set."
    exit 1
  fi

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"

  log_info "Retrieving DB security group..."
  DB_SG_ID=$(find_security_group_by_name "$VPC_ID" "$DB_SG_NAME")
  require_id "Security Group" "$DB_SG_NAME" "$DB_SG_ID"

  log_info "Retrieving DB subnet group..."
  DB_SUBNET_GROUP_RESULT=$(find_db_subnet_group_by_name "$DB_SUBNET_GROUP_NAME")
  require_id "DB Subnet Group" "$DB_SUBNET_GROUP_NAME" "$DB_SUBNET_GROUP_RESULT"

  log_info "Ensuring Aurora cluster exists..."
  CLUSTER_ID=$(ensure_aurora_cluster \
    "$AURORA_CLUSTER_IDENTIFIER" \
    "$DB_SUBNET_GROUP_NAME" \
    "$DB_SG_ID")

  require_id "Aurora Cluster" "$AURORA_CLUSTER_IDENTIFIER" "$CLUSTER_ID"

  wait_for_aurora_cluster "$CLUSTER_ID"

  log_success "Aurora cluster configured successfully: $CLUSTER_ID"
}

main "$@"