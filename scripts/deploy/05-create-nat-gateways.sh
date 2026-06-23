#!/bin/bash

# 05-create-nat-gateways.sh
# Creates NAT Gateways for private application subnet outbound internet access.

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

# shellcheck source=../lib/networking.sh
source "$ROOT_DIR/scripts/lib/networking.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  local vpc_id
  vpc_id=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$vpc_id"
  log_success "Found VPC: $vpc_id"

  log_info "Retrieving public subnet IDs..."
  local public_subnet_a_id
  local public_subnet_b_id
  public_subnet_a_id=$(find_subnet_by_name "$vpc_id" "$PUBLIC_SUBNET_A_NAME")
  public_subnet_b_id=$(find_subnet_by_name "$vpc_id" "$PUBLIC_SUBNET_B_NAME")

  require_id "Subnet" "$PUBLIC_SUBNET_A_NAME" "$public_subnet_a_id"
  require_id "Subnet" "$PUBLIC_SUBNET_B_NAME" "$public_subnet_b_id"

  log_info "Retrieving private application route tables..."
  local private_app_rt_a_id
  local private_app_rt_b_id
  private_app_rt_a_id=$(find_route_table_by_name "$vpc_id" "$PRIVATE_APP_RT_A_NAME")
  private_app_rt_b_id=$(find_route_table_by_name "$vpc_id" "$PRIVATE_APP_RT_B_NAME")

  require_id "Route Table" "$PRIVATE_APP_RT_A_NAME" "$private_app_rt_a_id"
  require_id "Route Table" "$PRIVATE_APP_RT_B_NAME" "$private_app_rt_b_id"

  log_info "Ensuring Elastic IPs exist..."
  local eip_a_allocation_id
  local eip_b_allocation_id
  eip_a_allocation_id=$(ensure_eip "$EIP_A_NAME")
  eip_b_allocation_id=$(ensure_eip "$EIP_B_NAME")

  require_id "Elastic IP Allocation" "$EIP_A_NAME" "$eip_a_allocation_id"
  require_id "Elastic IP Allocation" "$EIP_B_NAME" "$eip_b_allocation_id"

  log_info "Ensuring NAT Gateways exist..."
  local nat_gw_a_id
  local nat_gw_b_id
  nat_gw_a_id=$(ensure_nat_gateway "$NAT_GW_A_NAME" "$public_subnet_a_id" "$eip_a_allocation_id")
  nat_gw_b_id=$(ensure_nat_gateway "$NAT_GW_B_NAME" "$public_subnet_b_id" "$eip_b_allocation_id")

  require_id "NAT Gateway" "$NAT_GW_A_NAME" "$nat_gw_a_id"
  require_id "NAT Gateway" "$NAT_GW_B_NAME" "$nat_gw_b_id"

  wait_for_nat_gateway "$nat_gw_a_id"
  wait_for_nat_gateway "$nat_gw_b_id"

  log_info "Creating private application default routes..."
  ensure_route_to_nat_gateway "$private_app_rt_a_id" "$nat_gw_a_id"
  ensure_route_to_nat_gateway "$private_app_rt_b_id" "$nat_gw_b_id"

  log_success "NAT Gateways created and private application routes configured successfully."
}

main "$@"