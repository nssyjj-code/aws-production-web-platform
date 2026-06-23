#!/bin/bash

# scripts/lib/autoscaling.sh
# Shared Auto Scaling deployment helpers.

create_auto_scaling_group() {
  local asg_name="$1"
  local launch_template_name="$2"
  local private_subnet_a_id="$3"
  local private_subnet_b_id="$4"
  local target_group_arn="$5"

  aws_cli autoscaling create-auto-scaling-group \
    --auto-scaling-group-name "$asg_name" \
    --launch-template "LaunchTemplateName=$launch_template_name,Version=\$Latest" \
    --min-size "$ASG_MIN_SIZE" \
    --max-size "$ASG_MAX_SIZE" \
    --desired-capacity "$ASG_DESIRED_CAPACITY" \
    --vpc-zone-identifier "$private_subnet_a_id,$private_subnet_b_id" \
    --target-group-arns "$target_group_arn" \
    --health-check-type ELB \
    --health-check-grace-period 300 \
    --tags \
      "Key=Name,Value=$PROJECT_NAME-app-instance,PropagateAtLaunch=true" \
      "Key=Project,Value=$PROJECT_NAME,PropagateAtLaunch=true" \
      "Key=Environment,Value=${ENVIRONMENT:-development},PropagateAtLaunch=true" \
      "Key=ManagedBy,Value=aws-cli,PropagateAtLaunch=true" \
      "Key=Tier,Value=app,PropagateAtLaunch=true"
}

enable_auto_scaling_metrics() {
  local asg_name="$1"

  log_info "Enabling Auto Scaling Group metrics: $asg_name"

  aws_cli autoscaling enable-metrics-collection \
    --auto-scaling-group-name "$asg_name" \
    --granularity "1Minute" \
    --metrics \
      GroupDesiredCapacity \
      GroupInServiceInstances \
      GroupPendingInstances \
      GroupTerminatingInstances

  log_success "Enabled Auto Scaling metrics: $asg_name"
}

wait_for_auto_scaling_group_capacity() {
  local asg_name="$1"
  local desired_capacity="$2"
  local max_attempts="${3:-30}"
  local sleep_seconds="${4:-20}"
  local attempt=1
  local in_service_count

  log_info "Waiting for ASG capacity: $asg_name"

  while (( attempt <= max_attempts )); do
    in_service_count=$(aws_cli autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$asg_name" \
      --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId | length(@)" \
      --output text 2>/dev/null || echo "0")

    log_info "ASG InService instances: $in_service_count/$desired_capacity"

    if [[ "$in_service_count" -ge "$desired_capacity" ]]; then
      log_success "ASG reached desired InService capacity: $asg_name"
      return 0
    fi

    sleep "$sleep_seconds"
    ((attempt++))
  done

  log_warning "ASG did not reach desired InService capacity within expected time: $asg_name"
  return 1
}

ensure_auto_scaling_group() {
  local asg_name="$1"
  local launch_template_name="$2"
  local private_subnet_a_id="$3"
  local private_subnet_b_id="$4"
  local target_group_arn="$5"
  local existing_asg

  existing_asg=$(find_auto_scaling_group_by_name "$asg_name")

  if ! exists "$existing_asg"; then
    log_info "Creating Auto Scaling Group: $asg_name"

    create_auto_scaling_group \
      "$asg_name" \
      "$launch_template_name" \
      "$private_subnet_a_id" \
      "$private_subnet_b_id" \
      "$target_group_arn"

    log_success "Created Auto Scaling Group: $asg_name"
  else
    log_success "Auto Scaling Group already exists: $asg_name"
  fi

  enable_auto_scaling_metrics "$asg_name"
  wait_for_auto_scaling_group_capacity "$asg_name" "$ASG_DESIRED_CAPACITY" || true

  echo "$asg_name"
}