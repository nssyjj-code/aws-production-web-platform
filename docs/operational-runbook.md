# Operational Runbook

## Overview

This document provides operational procedures for monitoring, troubleshooting, and maintaining the AWS Production Web Platform.

The purpose of this runbook is to provide repeatable steps for diagnosing application availability, infrastructure health, and common failure scenarios.

Architecture components covered:

* Application Load Balancer
* Auto Scaling Group
* EC2 application instances
* Aurora MySQL database
* VPC networking
* Security groups

---

# Service Health Overview

## Critical Components

| Component                 | Responsibility                              |
| ------------------------- | ------------------------------------------- |
| Application Load Balancer | Public traffic routing                      |
| Target Group              | Application health validation               |
| Auto Scaling Group        | Instance availability and scaling           |
| EC2 Instances             | Application compute layer                   |
| Aurora MySQL              | Database persistence                        |
| NAT Gateway               | Outbound connectivity for private resources |

---

# Initial Incident Response Checklist

When an application issue is reported:

## Step 1 — Verify Load Balancer Health

Check ALB status:

```bash
aws elbv2 describe-load-balancers \
  --names prod-web-app-alb
```

Verify:

* Load balancer state is active
* Availability Zones are enabled
* DNS name is reachable

---

## Step 2 — Check Target Group Health

Verify registered targets:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

Expected:

```text
TargetHealth.State = healthy
```

Investigate:

* unhealthy
* draining
* unused

Common causes:

* Application service stopped
* Failed health checks
* Security group restrictions
* Instance failures

---

# EC2 Troubleshooting

## Verify Instance State

Check running instances:

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"
```

Confirm:

* Instance running
* Correct subnet placement
* Status checks passing

---

## Check Instance Health

Review:

* CPU utilization
* Memory utilization
* Disk usage
* Application process status

Possible remediation:

Restart application services.

Replace unhealthy instances through Auto Scaling:

```bash
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <instance-id> \
  --should-decrement-desired-capacity false
```

---

# Auto Scaling Troubleshooting

Check Auto Scaling Group status:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names prod-web-asg
```

Validate:

* Desired capacity
* Minimum capacity
* Maximum capacity
* Instance lifecycle state

Expected:

```text
LifecycleState = InService
HealthStatus = Healthy
```

---

# Database Troubleshooting

## Aurora Cluster Health

Check database status:

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier prod-aurora-cluster
```

Verify:

* Cluster available
* Writer instance exists
* No failover events occurring

---

## Connectivity Issues

If EC2 cannot connect to Aurora:

Validate:

1. Aurora endpoint configuration
2. Database security group rules
3. Application security group permissions
4. Database credentials
5. Route table configuration

Expected traffic flow:

```text
EC2 Security Group
        ↓
Database Security Group
        ↓
Aurora MySQL :3306
```

---

# Networking Troubleshooting

## Public Traffic Issues

Validate:

Internet Gateway

```bash
aws ec2 describe-internet-gateways
```

Validate:

* Attached to VPC
* Public routes exist

Expected public route:

```text
0.0.0.0/0 → Internet Gateway
```

---

## Private Internet Access Issues

Check NAT Gateway:

```bash
aws ec2 describe-nat-gateways
```

Validate:

* NAT Gateway available
* Elastic IP attached
* Private route tables configured

Expected private route:

```text
0.0.0.0/0 → NAT Gateway
```

---

# Security Group Troubleshooting

Validate least-privilege communication:

Internet:

```text
Internet
 ↓
ALB Security Group
Port 80
```

Application:

```text
ALB Security Group
 ↓
Application Security Group
Port 80
```

Database:

```text
Application Security Group
 ↓
Database Security Group
Port 3306
```

Avoid:

* Opening SSH publicly
* Exposing database ports externally
* Using unrestricted inbound rules

---

# Scaling Events

During increased traffic:

Expected behavior:

1. CloudWatch detects increased utilization
2. Auto Scaling policy triggers
3. New EC2 instances launch
4. Instances register with Target Group
5. ALB begins routing traffic

Validate scaling:

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name prod-web-asg
```

---

# Recovery Procedures

## Replace Failed Application Instance

Recommended:

Allow Auto Scaling to replace failed instances automatically.

Manual replacement:

```bash
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <id> \
  --should-decrement-desired-capacity false
```

---

## Database Recovery

Possible recovery actions:

* Review Aurora events
* Validate cluster status
* Perform failover if required
* Restore from snapshot if data loss occurs

---

# Preventative Monitoring

Recommended production monitoring:

## CloudWatch Metrics

Monitor:

Application Load Balancer:

* HTTP 5XX errors
* Target response time
* Unhealthy host count

EC2:

* CPU utilization
* Instance status checks

Aurora:

* CPU utilization
* Database connections
* Free storage
* Read/write latency

---

# Operational Improvements

Future improvements:

* CloudWatch alarms
* Centralized logging
* Automated incident notifications
* AWS Systems Manager Session Manager
* CI/CD deployment validation
* Infrastructure as Code migration

---

# Summary

This runbook documents operational procedures required to support a production-style AWS environment.

The focus is not only deploying infrastructure but maintaining reliability, troubleshooting failures, and operating cloud services after deployment.