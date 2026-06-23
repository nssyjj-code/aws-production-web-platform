#!/bin/bash

# 12-create-rds-subnet-group.sh
# Creates an RDS subnet group using private database subnets.

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
export AWS_PAGER=""

# shellcheck source=../lib/logging.sh
source "$ROOT_DIR/scripts/lib/logging.sh"

# shellcheck source=../lib/aws.sh
source "$ROOT_DIR/scripts/lib/aws.sh"

# shellcheck source=../lib/validation.sh
source "$ROOT_DIR/scripts/lib/validation.sh"

# shellcheck source=../lib/database.sh
source "$ROOT_DIR/scripts/lib/database.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  local vpc_id
  vpc_id=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$vpc_id"
  log_success "Found VPC: $vpc_id"

  log_info "Retrieving private database subnet IDs..."
  local private_db_subnet_a_id
  local private_db_subnet_b_id

  private_db_subnet_a_id=$(find_subnet_by_name "$vpc_id" "$PRIVATE_DB_SUBNET_A_NAME")
  private_db_subnet_b_id=$(find_subnet_by_name "$vpc_id" "$PRIVATE_DB_SUBNET_B_NAME")

  require_id "Private DB Subnet" "$PRIVATE_DB_SUBNET_A_NAME" "$private_db_subnet_a_id"
  require_id "Private DB Subnet" "$PRIVATE_DB_SUBNET_B_NAME" "$private_db_subnet_b_id"

  log_success "Found private DB subnets"

  log_info "Ensuring DB subnet group exists..."
  local db_subnet_group_result
  db_subnet_group_result=$(ensure_db_subnet_group \
    "$DB_SUBNET_GROUP_NAME" \
    "$private_db_subnet_a_id" \
    "$private_db_subnet_b_id")

  require_id "DB Subnet Group" "$DB_SUBNET_GROUP_NAME" "$db_subnet_group_result"

  log_success "DB subnet group configured successfully: $db_subnet_group_result"
}

main "$@"