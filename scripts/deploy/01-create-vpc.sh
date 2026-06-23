#!/bin/bash

# 01-create-vpc.sh
# Creates the base VPC for the AWS Production Web Platform.

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

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

AWS_REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PROJECT_NAME="aws-production-web-platform"
VPC_NAME="$PROJECT_NAME-vpc"

command -v aws >/dev/null 2>&1 || {
  log_error "AWS CLI is not installed."
  exit 1
}

aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || {
  log_error "AWS credentials are invalid or expired."
  exit 1
}

log_info "Checking for existing VPC..."

EXISTING_VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" "Name=cidr-block,Values=$VPC_CIDR" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$EXISTING_VPC_ID" != "None" ]]; then
  log_info "VPC already exists: $EXISTING_VPC_ID"
  log_success "No changes made."
  exit 0
fi

log_info "Creating VPC..."

VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "$VPC_CIDR" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME},{Key=Project,Value=$PROJECT_NAME}]" \
  --query "Vpc.VpcId" \
  --output text)

log_info "VPC created: $VPC_ID"

log_info "Configuring VPC DNS settings..."

aws ec2 modify-vpc-attribute \
  --vpc-id "$VPC_ID" \
  --enable-dns-support "{\"Value\":true}" \
  --region "$AWS_REGION"

aws ec2 modify-vpc-attribute \
  --vpc-id "$VPC_ID" \
  --enable-dns-hostnames "{\"Value\":true}" \
  --region "$AWS_REGION"

log_success "VPC setup complete: $VPC_ID"