#!/bin/bash

# 05-create-nat-gateways.sh
# Creates NAT Gateways for private application subnet outbound internet access.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../config/environment.conf"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/aws.sh"
source "$SCRIPT_DIR/../lib/networking.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Retrieving public subnet IDs..."
  PUBLIC_SUBNET_A_ID=$(find_subnet_by_name "$VPC_ID" "$PUBLIC_SUBNET_A_NAME")
  PUBLIC_SUBNET_B_ID=$(find_subnet_by_name "$VPC_ID" "$PUBLIC_SUBNET_B_NAME")

  require_id "Subnet" "$PUBLIC_SUBNET_A_NAME" "$PUBLIC_SUBNET_A_ID"
  require_id "Subnet" "$PUBLIC_SUBNET_B_NAME" "$PUBLIC_SUBNET_B_ID"

  log_info "Retrieving private application route tables..."
  PRIVATE_APP_RT_A_ID=$(find_route_table_by_name "$VPC_ID" "$PRIVATE_APP_RT_A_NAME")
  PRIVATE_APP_RT_B_ID=$(find_route_table_by_name "$VPC_ID" "$PRIVATE_APP_RT_B_NAME")

  require_id "Route Table" "$PRIVATE_APP_RT_A_NAME" "$PRIVATE_APP_RT_A_ID"
  require_id "Route Table" "$PRIVATE_APP_RT_B_NAME" "$PRIVATE_APP_RT_B_ID"

  log_info "Ensuring Elastic IPs exist..."
  EIP_A_ALLOCATION_ID=$(ensure_eip "$EIP_A_NAME")
  EIP_B_ALLOCATION_ID=$(ensure_eip "$EIP_B_NAME")

  require_id "Elastic IP Allocation" "$EIP_A_NAME" "$EIP_A_ALLOCATION_ID"
  require_id "Elastic IP Allocation" "$EIP_B_NAME" "$EIP_B_ALLOCATION_ID"

  log_info "Ensuring NAT Gateways exist..."
  NAT_GW_A_ID=$(ensure_nat_gateway "$NAT_GW_A_NAME" "$PUBLIC_SUBNET_A_ID" "$EIP_A_ALLOCATION_ID")
  NAT_GW_B_ID=$(ensure_nat_gateway "$NAT_GW_B_NAME" "$PUBLIC_SUBNET_B_ID" "$EIP_B_ALLOCATION_ID")

  require_id "NAT Gateway" "$NAT_GW_A_NAME" "$NAT_GW_A_ID"
  require_id "NAT Gateway" "$NAT_GW_B_NAME" "$NAT_GW_B_ID"

  wait_for_nat_gateway "$NAT_GW_A_ID"
  wait_for_nat_gateway "$NAT_GW_B_ID"

  log_info "Creating private application default routes..."
  ensure_route_to_nat_gateway "$PRIVATE_APP_RT_A_ID" "$NAT_GW_A_ID"
  ensure_route_to_nat_gateway "$PRIVATE_APP_RT_B_ID" "$NAT_GW_B_ID"

  log_success "NAT Gateways created and private application routes configured successfully."
}

main "$@"