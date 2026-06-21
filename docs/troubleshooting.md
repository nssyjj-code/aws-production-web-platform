# Troubleshooting

This document contains common deployment issues encountered while building this platform.

---

## AWS Credentials

### Problem

```text
Unable to locate credentials
```

### Resolution

Configure AWS CLI credentials:

```bash
aws configure
```

Verify:

```bash
aws sts get-caller-identity
```

---

## Duplicate Resource Errors

### Problem

A deployment script reports that a resource already exists.

### Resolution

Deployment scripts are designed to be idempotent.

If a duplicate resource exists from outside the project, remove it manually or update the project configuration to use unique resource names.

---

## Aurora Creation Timeout

### Problem

Aurora deployment appears to hang.

### Resolution

Aurora creation typically requires several minutes.

Monitor status:

```bash
aws rds describe-db-clusters
```

---

## NAT Gateway Pending

### Problem

NAT Gateway remains in a `pending` state.

### Resolution

This is expected during creation.

Wait until the state changes to:

```text
available
```

before continuing deployment.

---

## Target Group Health

### Problem

Instances remain unhealthy.

### Resolution

Verify:

* EC2 instances are running.
* The Auto Scaling Group has registered instances.
* Security groups allow application traffic.
* The application responds to the configured health check path.

---

## Systems Manager

### Problem

Session Manager cannot connect.

### Resolution

Verify:

* The EC2 IAM role is attached.
* The `AmazonSSMManagedInstanceCore` policy is attached.
* The instance has outbound internet access through a NAT Gateway.
