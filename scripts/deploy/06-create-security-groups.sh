#!/bin/bash

# 06-create-security-groups.sh
# Creates layered security groups for the AWS Production Web Platform.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"
source "$(dirname "$0")/../../config/environment.conf"
source "$(dirname "$0")/../lib/validation.sh"
source "$(dirname "$0")/../lib/aws.sh"
source "$(dirname "$0")/../lib/security.sh"

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID..."
  VPC_ID=$(find_vpc_by_name "$VPC_NAME")
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Ensuring security groups exist..."

  ALB_SG_ID=$(ensure_security_group "$VPC_ID" "$ALB_SG_NAME" "Allows public web traffic to the Application Load Balancer" "alb")
  APP_SG_ID=$(ensure_security_group "$VPC_ID" "$APP_SG_NAME" "Allows application traffic from the ALB only" "app")
  DB_SG_ID=$(ensure_security_group "$VPC_ID" "$DB_SG_NAME" "Allows database traffic from the application tier only" "database")

  require_id "Security Group" "$ALB_SG_NAME" "$ALB_SG_ID"
  require_id "Security Group" "$APP_SG_NAME" "$APP_SG_ID"
  require_id "Security Group" "$DB_SG_NAME" "$DB_SG_ID"

  log_info "Configuring ALB security group rules..."
  ensure_ingress_cidr_rule "$ALB_SG_ID" "tcp" 80 80 "0.0.0.0/0" "Allow HTTP from internet"
  ensure_ingress_cidr_rule "$ALB_SG_ID" "tcp" 443 443 "0.0.0.0/0" "Allow HTTPS from internet"

  log_info "Configuring application security group rules..."
  ensure_ingress_sg_rule "$APP_SG_ID" "tcp" 80 80 "$ALB_SG_ID" "Allow HTTP from ALB"

  log_info "Configuring database security group rules..."
  ensure_ingress_sg_rule "$DB_SG_ID" "tcp" 3306 3306 "$APP_SG_ID" "Allow MySQL/Aurora from app tier"

  log_success "Security groups created and configured successfully."
}

main "$@"