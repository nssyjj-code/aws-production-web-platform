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

find_load_balancer_by_name() {
  local lb_name="$1"

  aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --names "$lb_name" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text 2>/dev/null || echo "None"
}

create_load_balancer() {
  local lb_name="$1"
  local public_subnet_a_id="$2"
  local public_subnet_b_id="$3"
  local alb_sg_id="$4"

  aws elbv2 create-load-balancer \
    --region "$AWS_REGION" \
    --name "$lb_name" \
    --subnets "$public_subnet_a_id" "$public_subnet_b_id" \
    --security-groups "$alb_sg_id" \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --tags "Key=Name,Value=$lb_name" "Key=Project,Value=$PROJECT_NAME" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text
}

ensure_load_balancer() {
  local lb_name="$1"
  local public_subnet_a_id="$2"
  local public_subnet_b_id="$3"
  local alb_sg_id="$4"
  local lb_arn

  lb_arn=$(find_load_balancer_by_name "$lb_name")

  if [[ "$lb_arn" == "None" || -z "$lb_arn" ]]; then
    log_info "Creating Application Load Balancer: $lb_name" >&2

    if ! lb_arn=$(create_load_balancer "$lb_name" "$public_subnet_a_id" "$public_subnet_b_id" "$alb_sg_id"); then
      log_error "Failed to create Application Load Balancer: $lb_name" >&2
      exit 1
    fi

    log_success "Created Application Load Balancer: $lb_arn" >&2
  else
    log_success "Application Load Balancer already exists: $lb_name" >&2
  fi

  echo "$lb_arn"
}

find_http_listener() {
  local lb_arn="$1"

  aws elbv2 describe-listeners \
    --region "$AWS_REGION" \
    --load-balancer-arn "$lb_arn" \
    --query "Listeners[?Protocol=='HTTP' && Port==\`80\`].ListenerArn | [0]" \
    --output text 2>/dev/null || echo "None"
}

create_http_listener() {
  local lb_arn="$1"
  local target_group_arn="$2"

  aws elbv2 create-listener \
    --region "$AWS_REGION" \
    --load-balancer-arn "$lb_arn" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn="$target_group_arn" \
    --query "Listeners[0].ListenerArn" \
    --output text
}

ensure_http_listener() {
  local lb_arn="$1"
  local target_group_arn="$2"
  local listener_arn

  listener_arn=$(find_http_listener "$lb_arn")

  if [[ "$listener_arn" == "None" || -z "$listener_arn" ]]; then
    log_info "Creating HTTP listener on port 80" >&2

    if ! listener_arn=$(create_http_listener "$lb_arn" "$target_group_arn"); then
      log_error "Failed to create HTTP listener for ALB: $lb_arn" >&2
      exit 1
    fi

    log_success "Created HTTP listener: $listener_arn" >&2
  else
    log_success "HTTP listener already exists: $listener_arn" >&2
  fi

  echo "$listener_arn"
}