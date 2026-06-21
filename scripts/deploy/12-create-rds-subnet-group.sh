#!/bin/bash

# 12-create-rds-subnet-group.sh
# Creates an RDS subnet group using private database subnets.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../../config/environment.conf"
source "$(dirname "$0")/../lib/validation.sh"
source "$(dirname "$0")/../lib/aws.sh"
source "$(dirname "$0")/../lib/database.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Retrieving private database subnet IDs..."
  PRIVATE_DB_SUBNET_A_ID=$(find_subnet_by_name "$VPC_ID" "$PRIVATE_DB_SUBNET_A_NAME")
  PRIVATE_DB_SUBNET_B_ID=$(find_subnet_by_name "$VPC_ID" "$PRIVATE_DB_SUBNET_B_NAME")

  require_id "Private DB Subnet" "$PRIVATE_DB_SUBNET_A_NAME" "$PRIVATE_DB_SUBNET_A_ID"
  require_id "Private DB Subnet" "$PRIVATE_DB_SUBNET_B_NAME" "$PRIVATE_DB_SUBNET_B_ID"

  log_success "Found private DB subnets: $PRIVATE_DB_SUBNET_A_ID, $PRIVATE_DB_SUBNET_B_ID"

  log_info "Ensuring DB subnet group exists..."
  DB_SUBNET_GROUP_RESULT=$(ensure_db_subnet_group \
    "$DB_SUBNET_GROUP_NAME" \
    "$PRIVATE_DB_SUBNET_A_ID" \
    "$PRIVATE_DB_SUBNET_B_ID")

  require_id "DB Subnet Group" "$DB_SUBNET_GROUP_NAME" "$DB_SUBNET_GROUP_RESULT"

  log_success "DB subnet group configured successfully: $DB_SUBNET_GROUP_RESULT"
}

main "$@"