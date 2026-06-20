#!/bin/bash

# 02-configure-aws.sh
# Verifies local AWS CLI configuration.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"

AWS_REGION="us-east-1"
AWS_PROFILE_NAME="${AWS_PROFILE:-}"

log_info "Checking AWS CLI configuration..."

if ! command -v aws >/dev/null 2>&1; then
  log_error "AWS CLI is not installed."
  exit 1
fi

if [[ -n "$AWS_PROFILE_NAME" ]]; then
  IDENTITY=$(aws sts get-caller-identity --profile "$AWS_PROFILE_NAME" --region "$AWS_REGION" --output json)
else
  IDENTITY=$(aws sts get-caller-identity --region "$AWS_REGION" --output json)
fi

ACCOUNT_ID=$(echo "$IDENTITY" | jq -r ".Account")
ARN=$(echo "$IDENTITY" | jq -r ".Arn")

log_success "AWS CLI credentials are valid."

if [[ -n "$AWS_PROFILE_NAME" ]]; then
  log_info "Profile: $AWS_PROFILE_NAME"
else
  log_info "Profile: default credential chain"
fi

log_info "Region: $AWS_REGION"
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