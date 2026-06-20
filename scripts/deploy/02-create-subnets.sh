#!/bin/bash

# 02-create-subnets.sh
# Creates public, private application, and private database subnets.

set -euo pipefail

source "$(dirname "$0")/../lib/logging.sh"

AWS_REGION="us-east-1"
PROJECT_NAME="aws-production-web-platform"
VPC_NAME="$PROJECT_NAME-vpc"

AZ1="us-east-1a"
AZ2="us-east-1b"

PUBLIC_SUBNET_AZ1_CIDR="10.0.1.0/24"
PUBLIC_SUBNET_AZ2_CIDR="10.0.2.0/24"
PRIVATE_APP_SUBNET_AZ1_CIDR="10.0.11.0/24"
PRIVATE_APP_SUBNET_AZ2_CIDR="10.0.12.0/24"
PRIVATE_DB_SUBNET_AZ1_CIDR="10.0.21.0/24"
PRIVATE_DB_SUBNET_AZ2_CIDR="10.0.22.0/24"

command -v aws >/dev/null 2>&1 || {
  log_error "AWS CLI is not installed."
  exit 1
}

aws sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || {
  log_error "AWS credentials are invalid or expired."
  exit 1
}

log_info "Retrieving VPC ID for $VPC_NAME..."

VPC_ID=$(aws ec2 describe-vpcs \
  --region "$AWS_REGION" \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [[ "$VPC_ID" == "None" ]]; then
  log_error "VPC $VPC_NAME not found. Run 01-create-vpc.sh first."
  exit 1
fi

log_success "Found VPC: $VPC_ID"

log_info "Creating public subnet in $AZ1..."

PUBLIC_SUBNET_AZ1_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PUBLIC_SUBNET_AZ1_CIDR" \
  --availability-zone "$AZ1" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-public-subnet-az1},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=public}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created public subnet AZ1: $PUBLIC_SUBNET_AZ1_ID"

log_info "Creating public subnet in $AZ2..."

PUBLIC_SUBNET_AZ2_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PUBLIC_SUBNET_AZ2_CIDR" \
  --availability-zone "$AZ2" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-public-subnet-az2},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=public}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created public subnet AZ2: $PUBLIC_SUBNET_AZ2_ID"

log_info "Creating private app subnet in $AZ1..."

PRIVATE_APP_SUBNET_AZ1_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_APP_SUBNET_AZ1_CIDR" \
  --availability-zone "$AZ1" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-private-app-subnet-az1},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=private-app}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created private app subnet AZ1: $PRIVATE_APP_SUBNET_AZ1_ID"

log_info "Creating private app subnet in $AZ2..."

PRIVATE_APP_SUBNET_AZ2_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_APP_SUBNET_AZ2_CIDR" \
  --availability-zone "$AZ2" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-private-app-subnet-az2},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=private-app}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created private app subnet AZ2: $PRIVATE_APP_SUBNET_AZ2_ID"

log_info "Creating private database subnet in $AZ1..."

PRIVATE_DB_SUBNET_AZ1_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_DB_SUBNET_AZ1_CIDR" \
  --availability-zone "$AZ1" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-private-db-subnet-az1},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=private-db}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created private database subnet AZ1: $PRIVATE_DB_SUBNET_AZ1_ID"

log_info "Creating private database subnet in $AZ2..."

PRIVATE_DB_SUBNET_AZ2_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_DB_SUBNET_AZ2_CIDR" \
  --availability-zone "$AZ2" \
  --region "$AWS_REGION" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT_NAME-private-db-subnet-az2},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=private-db}]" \
  --query "Subnet.SubnetId" \
  --output text)

log_success "Created private database subnet AZ2: $PRIVATE_DB_SUBNET_AZ2_ID"

log_success "Subnet creation complete."