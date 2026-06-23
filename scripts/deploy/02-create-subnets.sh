#!/bin/bash

# 02-create-subnets.sh
# Creates public, private application, and private database subnets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

AWS_REGION="us-east-1"
PROJECT_NAME="aws-production-web-platform"
VPC_NAME="$PROJECT_NAME-vpc"

AZ1="us-east-1a"
AZ2="us-east-1b"

command -v aws >/dev/null 2>&1 || {
  log_error "AWS CLI is not installed."
  exit 1
}

aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || {
  log_error "AWS credentials are invalid or expired."
  exit 1
}

log_info "Retrieving VPC ID for $VPC_NAME..."

VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
  log_error "VPC $VPC_NAME not found. Run 01-create-vpc.sh first."
  exit 1
fi

log_success "Found VPC: $VPC_ID"

create_subnet() {
  local subnet_name="$1"
  local cidr_block="$2"
  local availability_zone="$3"
  local tier="$4"
  local existing_subnet_id
  local subnet_id

  log_info "Checking subnet: $subnet_name"

  existing_subnet_id=$(aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters \
      "Name=vpc-id,Values=$VPC_ID" \
      "Name=tag:Name,Values=$subnet_name" \
      "Name=cidr-block,Values=$cidr_block" \
    --query "Subnets[0].SubnetId" \
    --output text)

  if [[ "$existing_subnet_id" != "None" && -n "$existing_subnet_id" ]]; then
    subnet_id="$existing_subnet_id"
    log_info "Subnet already exists: $subnet_name ($subnet_id)"
  else
    log_info "Creating subnet: $subnet_name"

    subnet_id=$(aws ec2 create-subnet \
      --vpc-id "$VPC_ID" \
      --cidr-block "$cidr_block" \
      --availability-zone "$availability_zone" \
      --region "$AWS_REGION" \
      --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$subnet_name},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=$tier}]" \
      --query "Subnet.SubnetId" \
      --output text)

    log_success "Created subnet: $subnet_name ($subnet_id)"
  fi

  if [[ "$tier" == "public" ]]; then
    log_info "Enabling auto-assign public IPv4 for $subnet_name"

    aws ec2 modify-subnet-attribute \
      --region "$AWS_REGION" \
      --subnet-id "$subnet_id" \
      --map-public-ip-on-launch

    log_success "Auto-assign public IPv4 enabled for $subnet_name"
  fi
}

create_subnet "$PROJECT_NAME-public-subnet-az1" "10.0.1.0/24" "$AZ1" "public"
create_subnet "$PROJECT_NAME-public-subnet-az2" "10.0.2.0/24" "$AZ2" "public"

create_subnet "$PROJECT_NAME-private-app-subnet-az1" "10.0.11.0/24" "$AZ1" "private-app"
create_subnet "$PROJECT_NAME-private-app-subnet-az2" "10.0.12.0/24" "$AZ2" "private-app"

create_subnet "$PROJECT_NAME-private-db-subnet-az1" "10.0.21.0/24" "$AZ1" "private-db"
create_subnet "$PROJECT_NAME-private-db-subnet-az2" "10.0.22.0/24" "$AZ2" "private-db"

log_success "Subnet setup complete."