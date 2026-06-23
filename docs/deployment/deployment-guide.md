# Deployment Guide

## Overview

This document describes the deployment process for the AWS Production Web Platform.

The deployment process provisions a highly available three-tier AWS environment using AWS CLI automation.

The goal of this deployment process is to create a repeatable, validated, and recoverable infrastructure lifecycle.

Infrastructure components deployed:

* VPC networking
* Public and private subnets
* Internet Gateway
* NAT Gateways
* Route tables
* Security groups
* IAM resources
* Application Load Balancer
* Target Groups
* Launch Templates
* Auto Scaling Group
* EC2 application instances
* Aurora MySQL database

---

# Deployment Workflow

Infrastructure is deployed in dependency order to ensure resources exist before dependent services are created.

Deployment flow:

```text
Authentication
      |
      v
Configuration Loading
      |
      v
Networking Layer
      |
      v
Security Layer
      |
      v
Compute Layer
      |
      v
Load Balancing Layer
      |
      v
Database Layer
      |
      v
Validation
```

---

# Prerequisites

Before deployment, verify the following tools and access requirements.

Required:

* AWS account
* AWS CLI v2
* Git
* Bash shell
* IAM permissions required to provision project resources

---

## AWS CLI Validation

Verify AWS CLI installation:

```bash
aws --version
```

Expected:

```text
aws-cli/2.x
```

---

# Repository Setup

Clone the repository:

```bash
git clone https://github.com/nssyjj-code/aws-production-web-platform.git

cd aws-production-web-platform
```

---

# AWS Authentication

Configure AWS credentials:

```bash
aws configure
```

Validate the authenticated identity:

```bash
aws sts get-caller-identity
```

Confirm:

* Correct AWS account
* Correct IAM identity
* Expected permissions

Infrastructure deployment should only be performed after verifying the active AWS identity.

---

# Region Configuration

Default deployment region:

```text
us-east-1
```

Verify configured region:

```bash
aws configure get region
```

---

# Environment Configuration

Deployment variables are managed through:

```text
config/environment.conf
```

Configuration values include:

* AWS region
* Resource naming
* Network CIDR ranges
* Instance configuration
* Database configuration
* Scaling configuration

Deployment scripts load this file during execution.

---

# Database Credentials

Database credentials are provided through environment variables during deployment.

Example:

```bash
export DB_MASTER_USERNAME="adminuser"
export DB_MASTER_PASSWORD="ReplaceWithAStrongPassword"
```

This prevents database credentials from being stored in:

* Deployment scripts
* Configuration files
* Source control

Production environments should use AWS Secrets Manager or another secrets management solution.

---

# Deployment Execution

Start deployment:

```bash
./scripts/deploy/deploy.sh
```

The deployment automation provisions resources in dependency order.

---

# Deployment Stages

## Stage 1 — Network Foundation

Creates:

* VPC
* Availability Zone layout
* Public subnets
* Private application subnets
* Private database subnets

Validation:

```bash
aws ec2 describe-vpcs
```

---

## Stage 2 — Network Routing

Creates:

* Internet Gateway
* Elastic IP addresses
* NAT Gateways
* Route tables
* Route associations

Expected public routing:

```text
0.0.0.0/0 → Internet Gateway
```

Expected private routing:

```text
0.0.0.0/0 → NAT Gateway
```

---

## Stage 3 — Security Layer

Creates security groups enforcing tier isolation.

Traffic model:

```text
Internet
    |
    v
Application Load Balancer
    |
    v
Application Instances
    |
    v
Aurora MySQL
```

Rules:

Load Balancer:

```text
Inbound:
HTTP 80 from Internet
```

Application:

```text
Inbound:
HTTP 80 from ALB Security Group
```

Database:

```text
Inbound:
MySQL 3306 from Application Security Group
```

---

## Stage 4 — IAM Configuration

Creates:

* EC2 IAM role
* Instance profile
* Required permissions

IAM permissions allow EC2 resources to interact securely with AWS services without embedded credentials.

---

## Stage 5 — Compute Deployment

Creates:

* Launch Template
* Auto Scaling Group
* EC2 instances

Validate:

```bash
aws autoscaling describe-auto-scaling-groups
```

Expected:

```text
LifecycleState = InService
HealthStatus = Healthy
```

---

## Stage 6 — Load Balancer Deployment

Creates:

* Application Load Balancer
* Target Group
* Listener configuration

Validate:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

Expected:

```text
TargetHealth.State = healthy
```

---

## Stage 7 — Database Deployment

Creates:

* Aurora subnet group
* Aurora MySQL cluster
* Aurora writer instance

Validate:

```bash
aws rds describe-db-clusters
```

Expected:

```text
Status = available
```

---

# Post Deployment Validation

Run environment validation:

```bash
./scripts/validation/verify-environment.sh
```

Validation confirms:

## Networking

* VPC exists
* Subnets are deployed across Availability Zones
* Routes are configured correctly

## Compute

* Auto Scaling Group is active
* Instances are healthy
* Target checks are passing

## Database

* Aurora cluster is available
* Database networking is configured

## Security

Confirms:

* EC2 instances are private
* Database is not publicly accessible
* Security groups follow least privilege access

---

# Deployment Troubleshooting

Common deployment failures:

| Issue               | Possible Cause                |
| ------------------- | ----------------------------- |
| AccessDenied        | Missing IAM permissions       |
| DependencyViolation | Resource dependency conflict  |
| LimitExceeded       | AWS quota exceeded            |
| InvalidParameter    | Incorrect configuration value |
| AuthFailure         | Incorrect AWS credentials     |

Recommended troubleshooting process:

1. Review deployment output
2. Identify failed AWS service
3. Validate configuration
4. Verify permissions
5. Correct issue
6. Retry deployment

---

# Rollback Procedure

If deployment cannot be recovered, remove the environment:

```bash
./scripts/cleanup/destroy-environment.sh
```

The destroy workflow removes resources using dependency-aware ordering.

Cleanup includes:

* Application resources
* Load balancing resources
* Compute resources
* Database resources
* Networking resources
* IAM resources

---

# Production Improvements

Future production enhancements:

* Infrastructure as Code migration
* CI/CD pipeline deployment
* Automated testing
* Blue/green deployments
* Canary releases
* Deployment approval workflows
* Automated rollback mechanisms
* Secrets Manager integration

---

# Summary

This deployment process demonstrates complete infrastructure lifecycle management.

The focus is not only creating AWS resources, but building a repeatable, secure, and operationally maintainable deployment workflow.