# Incident Scenarios

## Overview

This document contains simulated production incidents performed against the AWS Production Web Platform.

The purpose of these scenarios is to demonstrate operational troubleshooting, root cause analysis, and recovery procedures.

Each incident follows the process:

1. Identify symptoms
2. Investigate affected services
3. Determine root cause
4. Apply remediation
5. Document preventative improvements

---

# Incident 001 — Application Load Balancer Returns 503 Errors

## Severity

SEV-2

## Scenario

Users report the website is unavailable.

HTTP requests to the Application Load Balancer return:

```text
503 Service Unavailable
```

---

## Initial Investigation

Verify Application Load Balancer state:

```bash
aws elbv2 describe-load-balancers \
  --names prod-web-app-alb
```

Validate:

* ALB is active
* Availability Zones are enabled

---

## Target Group Investigation

Check registered targets:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

Finding:

```text
TargetHealth.State = unhealthy
```

---

## Root Cause

EC2 instances failed ALB health checks.

Possible causes:

* Application process stopped
* Incorrect health check path
* Security group blocking traffic
* Instance startup failure

---

## Resolution

Validate application service status.

Restart application service if required.

If instance is unhealthy:

```bash
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <instance-id> \
  --should-decrement-desired-capacity false
```

Auto Scaling launches a replacement instance.

---

## Prevention

Recommended improvements:

* CloudWatch alarm for unhealthy targets
* Application health endpoint monitoring
* Centralized application logs

---

# Incident 002 — Database Connection Failure

## Severity

SEV-2

## Scenario

Application instances are healthy but users experience application errors.

Application logs show database connection failures.

---

## Investigation

Verify Aurora status:

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier prod-aurora-cluster
```

Expected:

```text
Status = available
```

---

## Network Validation

Check security group communication:

Expected flow:

```text
Application Security Group
        |
        v
Database Security Group
TCP 3306
```

---

## Root Cause

Database security group does not allow inbound MySQL traffic from application instances.

---

## Resolution

Restore security group rule:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <database-sg-id> \
  --protocol tcp \
  --port 3306 \
  --source-group <application-sg-id>
```

---

## Prevention

Recommended improvements:

* Infrastructure drift detection
* Security group change monitoring
* AWS Config rules

---

# Incident 003 — Private EC2 Instances Cannot Access Internet

## Severity

SEV-3

## Scenario

Application instances cannot:

* Download packages
* Receive software updates
* Access external APIs

---

## Investigation

Verify NAT Gateway status:

```bash
aws ec2 describe-nat-gateways
```

Expected:

```text
State = available
```

---

Check private route tables:

```bash
aws ec2 describe-route-tables
```

Expected route:

```text
0.0.0.0/0 → NAT Gateway
```

---

## Root Cause

Private subnet route table missing NAT Gateway route.

---

## Resolution

Restore outbound route:

```bash
aws ec2 create-route \
  --route-table-id <private-route-table-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id <nat-id>
```

---

## Prevention

Recommended improvements:

* Automated infrastructure validation
* Route monitoring
* Infrastructure as Code state management

---

# Incident 004 — Auto Scaling Group Not Replacing Instances

## Severity

SEV-2

## Scenario

EC2 instance fails but replacement capacity is not created.

---

## Investigation

Check Auto Scaling Group:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names prod-web-asg
```

Validate:

* Desired capacity
* Launch template
* Availability Zones

---

Review scaling activities:

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name prod-web-asg
```

---

## Possible Root Causes

* Invalid launch template
* Missing IAM permissions
* AMI unavailable
* Instance capacity issues

---

## Resolution

Correct failed dependency.

Refresh instances:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name prod-web-asg
```

---

## Prevention

Recommended improvements:

* Launch template validation
* CloudWatch scaling alarms
* Deployment testing pipeline

---

# Incident 005 — Infrastructure Destroy Failure

## Severity

SEV-3

## Scenario

Environment teardown script fails.

Error:

```text
ResourceInUse:
Target group is currently in use by a listener or rule
```

---

## Investigation

Review ALB dependencies:

```bash
aws elbv2 describe-listeners \
  --load-balancer-arn <alb-arn>
```

Finding:

Target Group is still attached to an ALB listener.

---

## Root Cause

AWS dependency order prevented deletion.

Incorrect order:

```text
Delete Target Group
        |
        v
Delete Listener
```

Correct order:

```text
Delete Listener
        |
        v
Delete Target Group
```

---

## Resolution

Updated destroy automation:

1. Remove listeners
2. Delete ALB
3. Delete Target Group

---

## Prevention

Improved cleanup automation with dependency-aware deletion logic.

---

# Lessons Learned

Operational reliability requires more than successful deployments.

Production environments require:

* Monitoring
* Dependency awareness
* Failure testing
* Recovery procedures
* Automation improvements

The goal is not preventing every failure, but reducing detection and recovery time.