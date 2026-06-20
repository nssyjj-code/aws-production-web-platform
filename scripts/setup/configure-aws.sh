#!/bin/bash

# 02-configure-aws.sh
# Helps verify or initialize local AWS CLI configuration.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"

AWS_REGION="us-east-1"
AWS_PROFILE_NAME="${AWS_PROFILE:-default}"

log_info "Checking AWS CLI configuration..."

if ! command -v aws >/dev/null 2>&1; then
  log_error "AWS CLI is not installed."
  exit 1
fi

if aws sts get-caller-identity --profile "$AWS_PROFILE_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  ACCOUNT_ID=$(aws sts get-caller-identity \
    --profile "$AWS_PROFILE_NAME" \
    --region "$AWS_REGION" \
    --query "Account" \
    --output text)

  ARN=$(aws sts get-caller-identity \
    --profile "$AWS_PROFILE_NAME" \
    --region "$AWS_REGION" \
    --query "Arn" \
    --output text)

  log_success "AWS CLI profile is configured."
  log_info "Profile: $AWS_PROFILE_NAME"
  log_info "Account ID: $ACCOUNT_ID"
  log_info "Identity: $ARN"
  exit 0
fi

log_warning "AWS CLI profile '$AWS_PROFILE_NAME' is not configured or credentials are invalid."
echo
echo "Run the following command to configure AWS CLI credentials:"
echo
echo "  aws configure --profile $AWS_PROFILE_NAME"
echo
echo "Recommended region:"
echo
echo "  $AWS_REGION"
echo

exit 1