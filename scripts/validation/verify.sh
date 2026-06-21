#!/bin/bash

# verify.sh
# Verifies core AWS Production Web Platform resources.

set -euo pipefail

source "./scripts/lib/logging.sh"
source "./config/environment.conf"

require_value() {
  local name="$1"
  local value="$2"

  if [[ "$value" == "None" || -z "$value" ]]; then
    log_error "$name verification failed."
    exit 1
  fi

  log_success "$name verified: $value"
}

log_info "Verifying AWS identity..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
require_value "AWS account" "$ACCOUNT_ID"

log_info "Verifying VPC..."
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)
require_value "VPC" "$VPC_ID"

log_info "Verifying ALB..."
ALB_STATE=$(aws elbv2 describe-load-balancers \
  --region "$AWS_REGION" \
  --names "$ALB_NAME" \
  --query "LoadBalancers[0].State.Code" \
  --output text)
require_value "ALB state" "$ALB_STATE"

log_info "Verifying Target Group..."
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --region "$AWS_REGION" \
  --names "$TARGET_GROUP_NAME" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)
require_value "Target Group" "$TARGET_GROUP_ARN"

log_info "Verifying Auto Scaling Group..."
ASG_NAME_RESULT=$(aws autoscaling describe-auto-scaling-groups \
  --region "$AWS_REGION" \
  --auto-scaling-group-names "$ASG_NAME" \
  --query "AutoScalingGroups[0].AutoScalingGroupName" \
  --output text)
require_value "Auto Scaling Group" "$ASG_NAME_RESULT"

log_info "Verifying Aurora cluster..."
AURORA_STATUS=$(aws rds describe-db-clusters \
  --region "$AWS_REGION" \
  --db-cluster-identifier "$AURORA_CLUSTER_IDENTIFIER" \
  --query "DBClusters[0].Status" \
  --output text)
require_value "Aurora cluster status" "$AURORA_STATUS"

log_info "Verifying Aurora writer instance..."
AURORA_INSTANCE_STATUS=$(aws rds describe-db-instances \
  --region "$AWS_REGION" \
  --db-instance-identifier "$AURORA_WRITER_INSTANCE_IDENTIFIER" \
  --query "DBInstances[0].DBInstanceStatus" \
  --output text)
require_value "Aurora instance status" "$AURORA_INSTANCE_STATUS"

log_info "Verifying ALB target health..."
aws elbv2 describe-target-health \
  --region "$AWS_REGION" \
  --target-group-arn "$TARGET_GROUP_ARN" \
  --output table

log_success "Platform verification complete."