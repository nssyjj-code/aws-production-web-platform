# Security Design

## Security Group Model

This project uses layered security groups.

```text
Internet
  ↓
ALB Security Group
  ↓
Application Security Group
  ↓
Database Security Group
```

## Rules

The ALB security group allows inbound HTTP and HTTPS from the internet.

The application security group allows inbound HTTP only from the ALB security group.

The database security group allows inbound MySQL/Aurora traffic only from the application security group.

## Access Model

EC2 instances use an IAM role and instance profile for AWS access.

SSH is intentionally not opened. The preferred operational access path is AWS Systems Manager Session Manager.