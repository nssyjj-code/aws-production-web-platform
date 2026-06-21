# Deployment Guide

## Prerequisites

Before deploying the platform, ensure the following software is installed:

* AWS CLI v2
* Git
* Bash
* An AWS account with sufficient IAM permissions

Configure AWS credentials:

```bash
aws configure
```

Verify authentication:

```bash
aws sts get-caller-identity
```

---

## Clone the Repository

```bash
git clone https://github.com/nssyjj-code/aws-production-web-platform.git

cd aws-production-web-platform
```

---

## Configure Environment

Review:

```text
config/environment.conf
```

Modify resource names or sizing if desired.

---

## Database Credentials

Aurora credentials are provided at runtime.

Example:

```bash
export DB_MASTER_USERNAME="adminuser"
export DB_MASTER_PASSWORD="ReplaceWithAStrongPassword"
```

---

## Deploy Infrastructure

Deploy the complete platform:

```bash
./deploy.sh
```

The deployment script provisions infrastructure in dependency order:

1. VPC
2. Subnets
3. Internet Gateway
4. Route Tables
5. NAT Gateways
6. Security Groups
7. IAM Role
8. Launch Template
9. Target Group
10. Load Balancer
11. Auto Scaling Group
12. DB Subnet Group
13. Aurora Cluster
14. Aurora Writer Instance

---

## Verify Deployment

```bash
./verify.sh
```

The verification script confirms that all core infrastructure resources were successfully created and are operational.

---

## Destroy Infrastructure

To prevent unnecessary AWS charges:

```bash
./destroy.sh
```

Resources are destroyed in reverse dependency order.
