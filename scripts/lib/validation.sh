#!/bin/bash

# scripts/lib/validation.sh
# Shared validation helpers for deployment scripts.

validate_aws_cli() {
  command -v aws >/dev/null 2>&1 || {
    log_error "AWS CLI is not installed."
    exit 1
  }
}

validate_aws_credentials() {
  aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || {
    log_error "AWS credentials are invalid or expired."
    exit 1
  }
}

log_aws_identity() {
  local account_id
  local caller_arn

  account_id=$(aws sts get-caller-identity --query "Account" --output text)
  caller_arn=$(aws sts get-caller-identity --query "Arn" --output text)

  log_info "Deploying to AWS Account: $account_id"
  log_info "Authenticated as: $caller_arn"
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

validate_prerequisites() {
  validate_aws_cli
  validate_aws_credentials
  log_aws_identity
}