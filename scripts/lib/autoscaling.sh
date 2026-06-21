#!/bin/bash

# scripts/lib/autoscaling.sh
# Shared Auto Scaling deployment helpers.

create_auto_scaling_group() {
  local asg_name="$1"
  local launch_template_name="$2"
  local private_subnet_a_id="$3"
  local private_subnet_b_id="$4"
  local target_group_arn="$5"

  aws autoscaling create-auto-scaling-group \
    --region "$AWS_REGION" \
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
      "Key=Tier,Value=app,PropagateAtLaunch=true" \
      "Key=Environment,Value=$ENVIRONMENT,PropagateAtLaunch=true"
}

ensure_auto_scaling_group() {
  local asg_name="$1"
  local launch_template_name="$2"
  local private_subnet_a_id="$3"
  local private_subnet_b_id="$4"
  local target_group_arn="$5"
  local existing_asg

  existing_asg=$(find_auto_scaling_group_by_name "$asg_name")

  if [[ "$existing_asg" == "None" || -z "$existing_asg" ]]; then
    log_info "Creating Auto Scaling Group: $asg_name" >&2

    create_auto_scaling_group \
      "$asg_name" \
      "$launch_template_name" \
      "$private_subnet_a_id" \
      "$private_subnet_b_id" \
      "$target_group_arn"

    log_success "Created Auto Scaling Group: $asg_name" >&2
  else
    log_success "Auto Scaling Group already exists: $asg_name" >&2
  fi

  echo "$asg_name"
}