#!/bin/bash
# scripts/cleanup/destroy-environment.sh
# Production-style teardown script for aws-production-web-platform

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/config/environment.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Missing config file: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

AWS_REGION="${AWS_REGION:-us-east-1}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*" >&2; }
err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

aws_cli() {
  aws --region "$AWS_REGION" "$@"
}

exists() {
  [[ -n "${1:-}" && "$1" != "None" && "$1" != "null" ]]
}

require_tools() {
  command -v aws >/dev/null 2>&1 || { err "AWS CLI is not installed."; exit 1; }
}

confirm_destroy() {
  echo
  warn "This will destroy AWS resources for project: $PROJECT_NAME"
  warn "Region: $AWS_REGION"
  warn "This action is destructive."
  echo
  read -r -p "Type DESTROY to continue: " CONFIRM

  if [[ "$CONFIRM" != "DESTROY" ]]; then
    log "Destroy cancelled."
    exit 0
  fi
}

get_vpc_id() {
  aws_cli ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=$VPC_NAME" \
    --query "Vpcs[0].VpcId" \
    --output text 2>/dev/null || echo "None"
}

delete_asg() {
  local asg="${ASG_NAME:-}"

  if ! exists "$asg"; then return; fi

  local found
  found=$(aws_cli autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$asg" \
    --query "AutoScalingGroups[0].AutoScalingGroupName" \
    --output text 2>/dev/null || echo "None")

  if exists "$found"; then
    log "Scaling Auto Scaling Group to 0: $asg"
    aws_cli autoscaling update-auto-scaling-group \
      --auto-scaling-group-name "$asg" \
      --min-size 0 \
      --desired-capacity 0 \
      --max-size 0 || true

    log "Deleting Auto Scaling Group: $asg"
    aws_cli autoscaling delete-auto-scaling-group \
      --auto-scaling-group-name "$asg" \
      --force-delete || true

    log "Waiting for Auto Scaling Group deletion: $asg"
    while true; do
      found=$(aws_cli autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$asg" \
        --query "AutoScalingGroups[0].AutoScalingGroupName" \
        --output text 2>/dev/null || echo "None")

      exists "$found" || break
      sleep 15
    done
  else
    log "Auto Scaling Group not found: $asg"
  fi
}

delete_alb() {
  local alb_arn

  alb_arn=$(aws_cli elbv2 describe-load-balancers \
    --names "$ALB_NAME" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text 2>/dev/null || echo "None")

  if exists "$alb_arn"; then
    log "Deleting Application Load Balancer: $ALB_NAME"
    aws_cli elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" || true

    log "Waiting for ALB deletion: $ALB_NAME"
    aws_cli elbv2 wait load-balancers-deleted --load-balancer-arns "$alb_arn" || true
  else
    log "ALB not found: $ALB_NAME"
  fi
}

delete_alb_listeners() {
  local alb_arn
  alb_arn=$(aws_cli elbv2 describe-load-balancers \
    --names "$ALB_NAME" \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text 2>/dev/null || echo "None")

  if ! exists "$alb_arn"; then
    log "ALB not found. Skipping listener cleanup."
    return
  fi

  local listener_arns
  listener_arns=$(aws_cli elbv2 describe-listeners \
    --load-balancer-arn "$alb_arn" \
    --query "Listeners[].ListenerArn" \
    --output text 2>/dev/null || true)

  for listener_arn in $listener_arns; do
    log "Deleting ALB listener: $listener_arn"
    aws_cli elbv2 delete-listener \
      --listener-arn "$listener_arn" || true
  done
}

delete_target_group() {
  local tg_arn

  tg_arn=$(aws_cli elbv2 describe-target-groups \
    --names "$TARGET_GROUP_NAME" \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text 2>/dev/null || echo "None")

  if exists "$tg_arn"; then
    log "Deleting Target Group: $TARGET_GROUP_NAME"
    aws_cli elbv2 delete-target-group --target-group-arn "$tg_arn" || true
  else
    log "Target Group not found: $TARGET_GROUP_NAME"
  fi
}

delete_aurora_instance() {
  local instance_id="${AURORA_WRITER_INSTANCE_IDENTIFIER:-}"

  if ! exists "$instance_id"; then return; fi

  local found
  found=$(aws_cli rds describe-db-instances \
    --db-instance-identifier "$instance_id" \
    --query "DBInstances[0].DBInstanceIdentifier" \
    --output text 2>/dev/null || echo "None")

  if exists "$found"; then
    log "Deleting Aurora DB instance: $instance_id"
    aws_cli rds delete-db-instance \
      --db-instance-identifier "$instance_id" \
      --skip-final-snapshot \
      --delete-automated-backups || true

    log "Waiting for Aurora DB instance deletion: $instance_id"
    aws_cli rds wait db-instance-deleted --db-instance-identifier "$instance_id" || true
  else
    log "Aurora DB instance not found: $instance_id"
  fi
}

delete_aurora_cluster() {
  local cluster_id="${AURORA_CLUSTER_IDENTIFIER:-}"

  if ! exists "$cluster_id"; then return; fi

  local found
  found=$(aws_cli rds describe-db-clusters \
    --db-cluster-identifier "$cluster_id" \
    --query "DBClusters[0].DBClusterIdentifier" \
    --output text 2>/dev/null || echo "None")

  if exists "$found"; then
    log "Deleting Aurora cluster: $cluster_id"
    aws_cli rds delete-db-cluster \
      --db-cluster-identifier "$cluster_id" \
      --skip-final-snapshot || true

    log "Waiting for Aurora cluster deletion: $cluster_id"
    aws_cli rds wait db-cluster-deleted --db-cluster-identifier "$cluster_id" || true
  else
    log "Aurora cluster not found: $cluster_id"
  fi
}

delete_db_subnet_group() {
  if [[ -z "${DB_SUBNET_GROUP_NAME:-}" ]]; then return; fi

  local found
  found=$(aws_cli rds describe-db-subnet-groups \
    --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" \
    --query "DBSubnetGroups[0].DBSubnetGroupName" \
    --output text 2>/dev/null || echo "None")

  if exists "$found"; then
    log "Deleting DB subnet group: $DB_SUBNET_GROUP_NAME"
    aws_cli rds delete-db-subnet-group \
      --db-subnet-group-name "$DB_SUBNET_GROUP_NAME" || true
  else
    log "DB subnet group not found: $DB_SUBNET_GROUP_NAME"
  fi
}

delete_launch_template() {
  local lt_id

  lt_id=$(aws_cli ec2 describe-launch-templates \
    --launch-template-names "$LAUNCH_TEMPLATE_NAME" \
    --query "LaunchTemplates[0].LaunchTemplateId" \
    --output text 2>/dev/null || echo "None")

  if exists "$lt_id"; then
    log "Deleting launch template: $LAUNCH_TEMPLATE_NAME"
    aws_cli ec2 delete-launch-template \
      --launch-template-id "$lt_id" >/dev/null || true
  else
    log "Launch template not found: $LAUNCH_TEMPLATE_NAME"
  fi
}

delete_iam_role() {
  if [[ -z "${EC2_INSTANCE_PROFILE_NAME:-}" || -z "${EC2_ROLE_NAME:-}" ]]; then return; fi

  log "Removing IAM instance profile and role if present."

  aws_cli iam remove-role-from-instance-profile \
    --instance-profile-name "$EC2_INSTANCE_PROFILE_NAME" \
    --role-name "$EC2_ROLE_NAME" 2>/dev/null || true

  aws_cli iam delete-instance-profile \
    --instance-profile-name "$EC2_INSTANCE_PROFILE_NAME" 2>/dev/null || true

  aws_cli iam detach-role-policy \
    --role-name "$EC2_ROLE_NAME" \
    --policy-arn "$SSM_MANAGED_POLICY_ARN" 2>/dev/null || true

  local policies
  policies=$(aws_cli iam list-role-policies \
    --role-name "$EC2_ROLE_NAME" \
    --query "PolicyNames[]" \
    --output text 2>/dev/null || true)

  for policy in $policies; do
    log "Deleting inline IAM policy: $policy"
    aws_cli iam delete-role-policy \
      --role-name "$EC2_ROLE_NAME" \
      --policy-name "$policy" 2>/dev/null || true
  done

  aws_cli iam delete-role \
    --role-name "$EC2_ROLE_NAME" 2>/dev/null || true
}

delete_nat_gateways_and_eips() {
  local nat_names=("$NAT_GW_A_NAME" "$NAT_GW_B_NAME")
  local eip_names=("$EIP_A_NAME" "$EIP_B_NAME")

  for nat_name in "${nat_names[@]}"; do
    local nat_id
    nat_id=$(aws_cli ec2 describe-nat-gateways \
      --filter "Name=tag:Name,Values=$nat_name" "Name=state,Values=pending,available,failed" \
      --query "NatGateways[0].NatGatewayId" \
      --output text 2>/dev/null || echo "None")

    if exists "$nat_id"; then
      log "Deleting NAT Gateway: $nat_name ($nat_id)"
      aws_cli ec2 delete-nat-gateway --nat-gateway-id "$nat_id" || true
    else
      log "NAT Gateway not found: $nat_name"
    fi
  done

  for nat_name in "${nat_names[@]}"; do
    local nat_id
    nat_id=$(aws_cli ec2 describe-nat-gateways \
      --filter "Name=tag:Name,Values=$nat_name" "Name=state,Values=deleting" \
      --query "NatGateways[0].NatGatewayId" \
      --output text 2>/dev/null || echo "None")

    if exists "$nat_id"; then
      log "Waiting for NAT Gateway deletion: $nat_id"
      aws_cli ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat_id" || true
    fi
  done

  for eip_name in "${eip_names[@]}"; do
    local allocation_id
    allocation_id=$(aws_cli ec2 describe-addresses \
      --filters "Name=tag:Name,Values=$eip_name" \
      --query "Addresses[0].AllocationId" \
      --output text 2>/dev/null || echo "None")

    if exists "$allocation_id"; then
      log "Releasing Elastic IP: $eip_name ($allocation_id)"
      aws_cli ec2 release-address --allocation-id "$allocation_id" || true
    else
      log "Elastic IP not found: $eip_name"
    fi
  done
}

delete_route_tables() {
  local vpc_id="$1"

  local route_tables=(
    "$PRIVATE_APP_RT_A_NAME"
    "$PRIVATE_APP_RT_B_NAME"
    "$PRIVATE_DB_RT_NAME"
    "$PUBLIC_RT_NAME"
  )

  for rt_name in "${route_tables[@]}"; do
    local rt_id
    rt_id=$(aws_cli ec2 describe-route-tables \
      --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$rt_name" \
      --query "RouteTables[0].RouteTableId" \
      --output text 2>/dev/null || echo "None")

    if exists "$rt_id"; then
      log "Disassociating route table associations: $rt_name ($rt_id)"

      local associations
      associations=$(aws_cli ec2 describe-route-tables \
        --route-table-ids "$rt_id" \
        --query "RouteTables[0].Associations[?Main==\`false\`].RouteTableAssociationId" \
        --output text 2>/dev/null || true)

      for assoc in $associations; do
        aws_cli ec2 disassociate-route-table \
          --association-id "$assoc" || true
      done

      log "Deleting route table: $rt_name ($rt_id)"
      aws_cli ec2 delete-route-table --route-table-id "$rt_id" || true
    else
      log "Route table not found: $rt_name"
    fi
  done
}

delete_security_groups() {
  local vpc_id="$1"

  local sg_names=(
    "$DB_SG_NAME"
    "$APP_SG_NAME"
    "$ALB_SG_NAME"
  )

  for sg_name in "${sg_names[@]}"; do
    local sg_id
    sg_id=$(aws_cli ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=$sg_name" \
      --query "SecurityGroups[0].GroupId" \
      --output text 2>/dev/null || echo "None")

    if exists "$sg_id"; then
      log "Deleting security group: $sg_name ($sg_id)"
      aws_cli ec2 delete-security-group --group-id "$sg_id" || true
    else
      log "Security group not found: $sg_name"
    fi
  done
}

delete_subnets() {
  local vpc_id="$1"

  local subnet_names=(
    "$PRIVATE_DB_SUBNET_A_NAME"
    "$PRIVATE_DB_SUBNET_B_NAME"
    "$PRIVATE_APP_SUBNET_A_NAME"
    "$PRIVATE_APP_SUBNET_B_NAME"
    "$PUBLIC_SUBNET_A_NAME"
    "$PUBLIC_SUBNET_B_NAME"
  )

  for subnet_name in "${subnet_names[@]}"; do
    local subnet_id
    subnet_id=$(aws_cli ec2 describe-subnets \
      --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$subnet_name" \
      --query "Subnets[0].SubnetId" \
      --output text 2>/dev/null || echo "None")

    if exists "$subnet_id"; then
      log "Deleting subnet: $subnet_name ($subnet_id)"
      aws_cli ec2 delete-subnet --subnet-id "$subnet_id" || true
    else
      log "Subnet not found: $subnet_name"
    fi
  done
}

delete_internet_gateway() {
  local vpc_id="$1"

  local igw_id
  igw_id=$(aws_cli ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$vpc_id" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text 2>/dev/null || echo "None")

  if exists "$igw_id"; then
    log "Detaching Internet Gateway: $igw_id"
    aws_cli ec2 detach-internet-gateway \
      --internet-gateway-id "$igw_id" \
      --vpc-id "$vpc_id" || true

    log "Deleting Internet Gateway: $igw_id"
    aws_cli ec2 delete-internet-gateway \
      --internet-gateway-id "$igw_id" || true
  else
    log "Internet Gateway not found for VPC: $vpc_id"
  fi
}

delete_vpc() {
  local vpc_id="$1"

  if exists "$vpc_id"; then
    log "Deleting VPC: $VPC_NAME ($vpc_id)"
    aws_cli ec2 delete-vpc --vpc-id "$vpc_id" || true
  else
    log "VPC not found: $VPC_NAME"
  fi
}

main() {
  require_tools
  confirm_destroy

  log "Starting environment destroy for $PROJECT_NAME in $AWS_REGION"

  delete_asg
  delete_alb_listeners
  delete_alb
  delete_target_group

  delete_aurora_instance
  delete_aurora_cluster
  delete_db_subnet_group

  delete_launch_template
  delete_iam_role

  local vpc_id
  vpc_id=$(get_vpc_id)

  if exists "$vpc_id"; then
    delete_nat_gateways_and_eips
    delete_route_tables "$vpc_id"
    delete_security_groups "$vpc_id"
    delete_subnets "$vpc_id"
    delete_internet_gateway "$vpc_id"
    delete_vpc "$vpc_id"
  else
    log "VPC not found. Skipping VPC-level cleanup."
  fi

  log "Destroy process complete."
}

main "$@"