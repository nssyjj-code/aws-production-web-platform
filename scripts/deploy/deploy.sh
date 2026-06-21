#!/bin/bash

# deploy.sh
# Deploys the AWS Production Web Platform in dependency order.

set -euo pipefail

run_step() {
  local script="$1"

  echo
  echo "=================================================="
  echo "Running: $script"
  echo "=================================================="

  "$script"
}

run_step "./scripts/deploy/01-create-vpc.sh"
run_step "./scripts/deploy/02-create-subnets.sh"
run_step "./scripts/deploy/03-create-internet-gateway.sh"
run_step "./scripts/deploy/04-create-route-tables.sh"
run_step "./scripts/deploy/05-create-nat-gateways.sh"
run_step "./scripts/deploy/06-create-security-groups.sh"
run_step "./scripts/deploy/07-create-ec2-iam-role.sh"
run_step "./scripts/deploy/08-create-launch-template.sh"
run_step "./scripts/deploy/09-create-target-group.sh"
run_step "./scripts/deploy/10-create-load-balancer.sh"
run_step "./scripts/deploy/11-create-auto-scaling-group.sh"
run_step "./scripts/deploy/12-create-rds-subnet-group.sh"
run_step "./scripts/deploy/13-create-aurora-cluster.sh"
run_step "./scripts/deploy/14-create-aurora-instance.sh"

echo
echo "Deployment complete."