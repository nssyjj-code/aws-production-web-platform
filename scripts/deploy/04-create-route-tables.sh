#!/bin/bash

# 04-create-route-tables.sh
# Creates and associates custom route tables for the AWS Production Web Platform VPC.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"

AWS_REGION="us-east-1"
PROJECT_NAME="aws-production-web-platform"
VPC_NAME="$PROJECT_NAME-vpc"

PUBLIC_RT_NAME="$PROJECT_NAME-public-rt"
PRIVATE_APP_RT_A_NAME="$PROJECT_NAME-private-app-rt-a"
PRIVATE_APP_RT_B_NAME="$PROJECT_NAME-private-app-rt-b"
PRIVATE_DB_RT_NAME="$PROJECT_NAME-private-db-rt"

PUBLIC_SUBNET_A_NAME="$PROJECT_NAME-public-subnet-az1"
PUBLIC_SUBNET_B_NAME="$PROJECT_NAME-public-subnet-az2"
PRIVATE_APP_SUBNET_A_NAME="$PROJECT_NAME-private-app-subnet-az1"
PRIVATE_APP_SUBNET_B_NAME="$PROJECT_NAME-private-app-subnet-az2"
PRIVATE_DB_SUBNET_A_NAME="$PROJECT_NAME-private-db-subnet-az1"
PRIVATE_DB_SUBNET_B_NAME="$PROJECT_NAME-private-db-subnet-az2"

validate_prerequisites() {
  command -v aws >/dev/null 2>&1 || {
    log_error "AWS CLI is not installed."
    exit 1
  }

  aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || {
    log_error "AWS credentials are invalid or expired."
    exit 1
  }
}

require_id() {
  local resource_type="$1"
  local resource_name="$2"
  local resource_id="$3"

  if [[ "$resource_id" == "None" || -z "$resource_id" ]]; then
    log_error "$resource_type not found: $resource_name"
    exit 1
  fi
}

get_vpc_id() {
  aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$VPC_NAME" \
    --query "Vpcs[0].VpcId" \
    --output text
}

get_igw_id() {
  aws ec2 describe-internet-gateways \
    --region "$AWS_REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text
}

get_subnet_id() {
  local subnet_name="$1"

  aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$subnet_name" \
    --query "Subnets[0].SubnetId" \
    --output text
}

get_route_table_id() {
  local route_table_name="$1"

  aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$route_table_name" \
    --query "RouteTables[0].RouteTableId" \
    --output text
}

create_route_table() {
  local route_table_name="$1"
  local tier="$2"

  aws ec2 create-route-table \
    --region "$AWS_REGION" \
    --vpc-id "$VPC_ID" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$route_table_name},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=$tier}]" \
    --query "RouteTable.RouteTableId" \
    --output text
}

get_or_create_route_table() {
  local route_table_name="$1"
  local tier="$2"
  local route_table_id

  route_table_id=$(get_route_table_id "$route_table_name")

  if [[ "$route_table_id" == "None" || -z "$route_table_id" ]]; then
    log_info "Creating route table: $route_table_name" >&2
    route_table_id=$(create_route_table "$route_table_name" "$tier")
    log_success "Created route table $route_table_name: $route_table_id" >&2
  else
    log_success "Route table already exists: $route_table_name ($route_table_id)" >&2
  fi

  echo "$route_table_id"
}

create_public_route() {
  local route_table_id="$1"

  if aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --route-table-ids "$route_table_id" \
    --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" \
    --output text | grep -q "$IGW_ID"; then
    log_success "Public internet route already exists for $route_table_id"
  else
    log_info "Creating public internet route for $route_table_id"

    aws ec2 create-route \
      --region "$AWS_REGION" \
      --route-table-id "$route_table_id" \
      --destination-cidr-block "0.0.0.0/0" \
      --gateway-id "$IGW_ID" >/dev/null

    log_success "Created route: 0.0.0.0/0 -> $IGW_ID"
  fi
}

associate_route_table() {
  local route_table_id="$1"
  local subnet_id="$2"
  local subnet_name="$3"

  local existing_association

  existing_association=$(aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --filters "Name=association.subnet-id,Values=$subnet_id" \
    --query "RouteTables[0].Associations[?SubnetId=='$subnet_id'].RouteTableAssociationId" \
    --output text)

  if [[ "$existing_association" != "None" && -n "$existing_association" ]]; then
    log_success "$subnet_name is already associated with a route table"
  else
    log_info "Associating $subnet_name with route table $route_table_id"

    aws ec2 associate-route-table \
      --region "$AWS_REGION" \
      --route-table-id "$route_table_id" \
      --subnet-id "$subnet_id" >/dev/null

    log_success "Associated $subnet_name with $route_table_id"
  fi
}

main() {
  validate_prerequisites

  ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
  CALLER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)

  log_info "Deploying to AWS Account: $ACCOUNT_ID"
  log_info "Authenticated as: $CALLER_ARN"

  log_info "Retrieving VPC ID..."
  VPC_ID=$(get_vpc_id)
  require_id "VPC" "$VPC_NAME" "$VPC_ID"
  log_success "Found VPC: $VPC_ID"

  log_info "Retrieving Internet Gateway ID..."
  IGW_ID=$(get_igw_id)
  require_id "Internet Gateway attached to VPC" "$VPC_ID" "$IGW_ID"
  log_success "Found Internet Gateway: $IGW_ID"

  PUBLIC_SUBNET_A_ID=$(get_subnet_id "$PUBLIC_SUBNET_A_NAME")
  PUBLIC_SUBNET_B_ID=$(get_subnet_id "$PUBLIC_SUBNET_B_NAME")
  PRIVATE_APP_SUBNET_A_ID=$(get_subnet_id "$PRIVATE_APP_SUBNET_A_NAME")
  PRIVATE_APP_SUBNET_B_ID=$(get_subnet_id "$PRIVATE_APP_SUBNET_B_NAME")
  PRIVATE_DB_SUBNET_A_ID=$(get_subnet_id "$PRIVATE_DB_SUBNET_A_NAME")
  PRIVATE_DB_SUBNET_B_ID=$(get_subnet_id "$PRIVATE_DB_SUBNET_B_NAME")

  require_id "Subnet" "$PUBLIC_SUBNET_A_NAME" "$PUBLIC_SUBNET_A_ID"
  require_id "Subnet" "$PUBLIC_SUBNET_B_NAME" "$PUBLIC_SUBNET_B_ID"
  require_id "Subnet" "$PRIVATE_APP_SUBNET_A_NAME" "$PRIVATE_APP_SUBNET_A_ID"
  require_id "Subnet" "$PRIVATE_APP_SUBNET_B_NAME" "$PRIVATE_APP_SUBNET_B_ID"
  require_id "Subnet" "$PRIVATE_DB_SUBNET_A_NAME" "$PRIVATE_DB_SUBNET_A_ID"
  require_id "Subnet" "$PRIVATE_DB_SUBNET_B_NAME" "$PRIVATE_DB_SUBNET_B_ID"

  PUBLIC_RT_ID=$(get_or_create_route_table "$PUBLIC_RT_NAME" "Public")
  PRIVATE_APP_RT_A_ID=$(get_or_create_route_table "$PRIVATE_APP_RT_A_NAME" "Private-App")
  PRIVATE_APP_RT_B_ID=$(get_or_create_route_table "$PRIVATE_APP_RT_B_NAME" "Private-App")
  PRIVATE_DB_RT_ID=$(get_or_create_route_table "$PRIVATE_DB_RT_NAME" "Private-DB")

  create_public_route "$PUBLIC_RT_ID"

  associate_route_table "$PUBLIC_RT_ID" "$PUBLIC_SUBNET_A_ID" "$PUBLIC_SUBNET_A_NAME"
  associate_route_table "$PUBLIC_RT_ID" "$PUBLIC_SUBNET_B_ID" "$PUBLIC_SUBNET_B_NAME"

  associate_route_table "$PRIVATE_APP_RT_A_ID" "$PRIVATE_APP_SUBNET_A_ID" "$PRIVATE_APP_SUBNET_A_NAME"
  associate_route_table "$PRIVATE_APP_RT_B_ID" "$PRIVATE_APP_SUBNET_B_ID" "$PRIVATE_APP_SUBNET_B_NAME"

  associate_route_table "$PRIVATE_DB_RT_ID" "$PRIVATE_DB_SUBNET_A_ID" "$PRIVATE_DB_SUBNET_A_NAME"
  associate_route_table "$PRIVATE_DB_RT_ID" "$PRIVATE_DB_SUBNET_B_ID" "$PRIVATE_DB_SUBNET_B_NAME"

  log_success "Route tables created and associated successfully."
}

main "$@"