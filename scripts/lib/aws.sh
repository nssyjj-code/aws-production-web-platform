#!/bin/bash

# scripts/lib/aws.sh
# Shared AWS resource lookup helpers.

find_vpc_by_name() {
  local vpc_name="$1"

  aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$vpc_name" \
    --query "Vpcs[0].VpcId" \
    --output text
}

find_igw_by_vpc_id() {
  local vpc_id="$1"

  aws ec2 describe-internet-gateways \
    --region "$AWS_REGION" \
    --filters "Name=attachment.vpc-id,Values=$vpc_id" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text
}

find_subnet_by_name() {
  local vpc_id="$1"
  local subnet_name="$2"

  aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$subnet_name" \
    --query "Subnets[0].SubnetId" \
    --output text
}

find_route_table_by_name() {
  local vpc_id="$1"
  local route_table_name="$2"

  aws ec2 describe-route-tables \
    --region "$AWS_REGION" \
    --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=$route_table_name" \
    --query "RouteTables[0].RouteTableId" \
    --output text
}

find_eip_allocation_by_name() {
  local eip_name="$1"

  aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=$eip_name" \
    --query "Addresses[0].AllocationId" \
    --output text
}

find_nat_gateway_by_name() {
  local nat_gateway_name="$1"

  aws ec2 describe-nat-gateways \
    --region "$AWS_REGION" \
    --filter "Name=tag:Name,Values=$nat_gateway_name" "Name=state,Values=pending,available" \
    --query "NatGateways[0].NatGatewayId" \
    --output text
}