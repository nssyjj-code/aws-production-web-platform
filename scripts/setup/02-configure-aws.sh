#!/bin/bash

# 02-configure-aws.sh
# Verifies local AWS CLI configuration and active AWS identity.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_PROFILE_NAME="${AWS_PROFILE:-}"

log_info "Checking AWS CLI configuration..."

if ! command -v aws >/dev/null 2>&1; then
  log_error "AWS CLI is not installed."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  log_error "jq is not installed. jq is required to parse AWS CLI identity output."
  exit 1
fi

AWS_ARGS=(--region "$AWS_REGION")

if [[ -n "$AWS_PROFILE_NAME" ]]; then
  AWS_ARGS+=(--profile "$AWS_PROFILE_NAME")
fi

if ! IDENTITY=$(aws sts get-caller-identity "${AWS_ARGS[@]}" --output json 2>/dev/null); then
  log_warning "AWS CLI credentials are not configured or are invalid."
  echo
  echo "Configure credentials with:"
  echo

  if [[ -n "$AWS_PROFILE_NAME" ]]; then
    echo "  aws configure --profile $AWS_PROFILE_NAME"
  else
    echo "  aws configure"
  fi

  echo
  echo "Recommended region:"
  echo
  echo "  $AWS_REGION"
  echo

  exit 1
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