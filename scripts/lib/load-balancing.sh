#!/bin/bash

# scripts/lib/load-balancing.sh
# Shared Elastic Load Balancing deployment helpers.

find_target_group_by_name() {
  local target_group_name="$1"

  aws elbv2 describe-target-groups \
    --region "$AWS_REGION" \
    --names "$target_group_name" \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text 2>/dev/null || echo "None"
}

create_target_group() {
  local target_group_name="$1"
  local vpc_id="$2"
  local protocol="$3"
  local port="$4"

  aws elbv2 create-target-group \
    --region "$AWS_REGION" \
    --name "$target_group_name" \
    --protocol "$protocol" \
    --port "$port" \
    --vpc-id "$vpc_id" \
    --target-type instance \
    --health-check-protocol HTTP \
    --health-check-path "/" \
    --health-check-port traffic-port \
    --matcher HttpCode=200 \
    --tags "Key=Name,Value=$target_group_name" "Key=Project,Value=$PROJECT_NAME" \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text
}

ensure_target_group() {
  local target_group_name="$1"
  local vpc_id="$2"
  local protocol="$3"
  local port="$4"
  local target_group_arn

  target_group_arn=$(find_target_group_by_name "$target_group_name")

  if [[ "$target_group_arn" == "None" || -z "$target_group_arn" ]]; then
    log_info "Creating target group: $target_group_name" >&2

    if ! target_group_arn=$(create_target_group "$target_group_name" "$vpc_id" "$protocol" "$port"); then
      log_error "Failed to create target group: $target_group_name" >&2
      exit 1
    fi

    log_success "Created target group: $target_group_arn" >&2
  else
    log_success "Target group already exists: $target_group_name" >&2
  fi

  echo "$target_group_arn"
}