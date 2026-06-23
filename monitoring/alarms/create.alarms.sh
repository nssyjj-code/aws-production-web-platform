#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config/environment.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Missing config file: $CONFIG_FILE"
  exit 1
fi

# shellcheck source=../../config/environment.conf
source "$CONFIG_FILE"

AWS_REGION="${AWS_REGION:-us-east-1}"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN:-}"

aws_cli() {
  aws --region "$AWS_REGION" "$@"
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_alb_dimension() {
  local alb_arn
  alb_arn=$(aws_cli elbv2 describe-load-balancers \
    --names "$ALB_NAME" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text)

  echo "$alb_arn" | awk -F'loadbalancer/' '{print $2}'
}

get_target_group_dimension() {
  local tg_arn
  tg_arn=$(aws_cli elbv2 describe-target-groups \
    --names "$TARGET_GROUP_NAME" \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)

  echo "$tg_arn" | awk -F':targetgroup/' '{print "targetgroup/" $2}'
}

alarm_actions_args=()
if [[ -n "$SNS_TOPIC_ARN" ]]; then
  alarm_actions_args=(--alarm-actions "$SNS_TOPIC_ARN")
fi

log "Discovering CloudWatch metric dimensions..."

LOAD_BALANCER_DIMENSION="$(get_alb_dimension)"
TARGET_GROUP_DIMENSION="$(get_target_group_dimension)"

log "Enabling Auto Scaling Group metrics..."

aws_cli autoscaling enable-metrics-collection \
  --auto-scaling-group-name "$ASG_NAME" \
  --granularity "1Minute" \
  --metrics \
    GroupDesiredCapacity \
    GroupInServiceInstances \
    GroupPendingInstances \
    GroupTerminatingInstances || true

log "Creating CloudWatch alarms..."

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-alb-unhealthy-targets" \
  --alarm-description "ALB has unhealthy targets registered in the target group." \
  --namespace "AWS/ApplicationELB" \
  --metric-name "UnHealthyHostCount" \
  --dimensions \
    Name=LoadBalancer,Value="$LOAD_BALANCER_DIMENSION" \
    Name=TargetGroup,Value="$TARGET_GROUP_DIMENSION" \
  --statistic Maximum \
  --period 60 \
  --evaluation-periods 2 \
  --datapoints-to-alarm 2 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-alb-5xx-errors" \
  --alarm-description "ALB is returning HTTP 5XX errors." \
  --namespace "AWS/ApplicationELB" \
  --metric-name "HTTPCode_ELB_5XX_Count" \
  --dimensions Name=LoadBalancer,Value="$LOAD_BALANCER_DIMENSION" \
  --statistic Sum \
  --period 60 \
  --evaluation-periods 3 \
  --datapoints-to-alarm 2 \
  --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-target-5xx-errors" \
  --alarm-description "Application targets are returning HTTP 5XX errors." \
  --namespace "AWS/ApplicationELB" \
  --metric-name "HTTPCode_Target_5XX_Count" \
  --dimensions Name=LoadBalancer,Value="$LOAD_BALANCER_DIMENSION" \
  --statistic Sum \
  --period 60 \
  --evaluation-periods 3 \
  --datapoints-to-alarm 2 \
  --threshold 10 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-alb-high-latency" \
  --alarm-description "ALB target response time is elevated." \
  --namespace "AWS/ApplicationELB" \
  --metric-name "TargetResponseTime" \
  --dimensions Name=LoadBalancer,Value="$LOAD_BALANCER_DIMENSION" \
  --statistic Average \
  --period 60 \
  --evaluation-periods 5 \
  --datapoints-to-alarm 3 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-asg-capacity-mismatch" \
  --alarm-description "Auto Scaling Group has fewer in-service instances than expected." \
  --namespace "AWS/AutoScaling" \
  --metric-name "GroupInServiceInstances" \
  --dimensions Name=AutoScalingGroupName,Value="$ASG_NAME" \
  --statistic Average \
  --period 60 \
  --evaluation-periods 3 \
  --datapoints-to-alarm 2 \
  --threshold 2 \
  --comparison-operator LessThanThreshold \
  --treat-missing-data breaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-aurora-high-cpu" \
  --alarm-description "Aurora writer instance CPU utilization is high." \
  --namespace "AWS/RDS" \
  --metric-name "CPUUtilization" \
  --dimensions Name=DBInstanceIdentifier,Value="$AURORA_WRITER_INSTANCE_IDENTIFIER" \
  --statistic Average \
  --period 300 \
  --evaluation-periods 3 \
  --datapoints-to-alarm 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

aws_cli cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT_NAME}-aurora-high-connections" \
  --alarm-description "Aurora writer instance has elevated database connections." \
  --namespace "AWS/RDS" \
  --metric-name "DatabaseConnections" \
  --dimensions Name=DBInstanceIdentifier,Value="$AURORA_WRITER_INSTANCE_IDENTIFIER" \
  --statistic Average \
  --period 300 \
  --evaluation-periods 3 \
  --datapoints-to-alarm 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  "${alarm_actions_args[@]}"

log "CloudWatch alarms created successfully."