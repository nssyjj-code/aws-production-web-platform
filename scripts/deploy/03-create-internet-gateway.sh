#!/bin/bash

# 03-create-internet-gateway.sh
# Creates and attaches an Internet Gateway for the AWS Production Web Platform VPC.
# This script is idempotent and safe to rerun.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

AWS_REGION="us-east-1"
PROJECT_NAME="aws-production-web-platform"

VPC_NAME="$PROJECT_NAME-vpc"
IGW_NAME="$PROJECT_NAME-igw"

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

get_vpc_id() {
  aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$VPC_NAME" \
    --query "Vpcs[0].VpcId" \
    --output text
}

get_existing_igw() {
  aws ec2 describe-internet-gateways \
    --region "$AWS_REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text
}

create_igw() {
  aws ec2 create-internet-gateway \
    --region "$AWS_REGION" \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$IGW_NAME},{Key=Project,Value=$PROJECT_NAME}]" \
    --query "InternetGateway.InternetGatewayId" \
    --output text
}

attach_igw() {
  aws ec2 attach-internet-gateway \
    --region "$AWS_REGION" \
    --internet-gateway-id "$IGW_ID" \
    --vpc-id "$VPC_ID" >/dev/null
}

verify_igw_attachment() {
  aws ec2 describe-internet-gateways \
    --region "$AWS_REGION" \
    --internet-gateway-ids "$IGW_ID" \
    --query "InternetGateways[0].Attachments[0].VpcId" \
    --output text
}

main() {
  validate_prerequisites

  log_info "Retrieving VPC ID for $VPC_NAME..."
  VPC_ID=$(get_vpc_id)

  if [[ "$VPC_ID" == "None" || -z "$VPC_ID" ]]; then
    log_error "VPC $VPC_NAME not found. Run 01-create-vpc.sh first."
    exit 1
  fi

  log_success "Found VPC: $VPC_ID"

  log_info "Checking for existing Internet Gateway attached to $VPC_ID..."
  IGW_ID=$(get_existing_igw)

  if [[ "$IGW_ID" == "None" || -z "$IGW_ID" ]]; then
    log_info "No Internet Gateway found. Creating one..."
    IGW_ID=$(create_igw)

    log_success "Created Internet Gateway: $IGW_ID"

    log_info "Attaching Internet Gateway $IGW_ID to VPC $VPC_ID..."
    attach_igw

    log_success "Attached Internet Gateway $IGW_ID to VPC $VPC_ID"
  else
    log_success "Internet Gateway already exists and is attached: $IGW_ID"
  fi

  log_info "Verifying Internet Gateway attachment..."
  ATTACHED_VPC_ID=$(verify_igw_attachment)

  if [[ "$ATTACHED_VPC_ID" != "$VPC_ID" ]]; then
    log_error "Internet Gateway verification failed. Expected $VPC_ID but found $ATTACHED_VPC_ID."
    exit 1
  fi

  log_success "Internet Gateway is correctly attached to VPC $VPC_ID."
}

main "$@"