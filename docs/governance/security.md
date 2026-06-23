# Security Design

## Overview

This document describes the security architecture and controls implemented for the AWS Production Web Platform.

The environment follows a defense-in-depth approach by applying security controls across multiple layers:

* Network isolation
* Identity and access management
* Least privilege access
* Secure administrative access
* Database protection
* Credential management

Security decisions are based on AWS cloud security best practices and the principle of least privilege.

---

# Security Architecture

The platform uses layered network security.

Traffic flow:

```text
Internet
    |
    v
Application Load Balancer
    |
    v
EC2 Application Instances
    |
    v
Aurora MySQL Database
```

Each tier only accepts required traffic from the previous layer.

---

# Network Security Design

## Public Tier

Resources:

* Application Load Balancer
* NAT Gateways

The public tier contains resources that require internet connectivity.

The Application Load Balancer is the only inbound entry point into the environment.

Allowed inbound traffic:

```text
Internet
    |
    v
ALB Security Group

HTTP 80
HTTPS 443 (production enhancement)
```

No application servers are directly exposed to the internet.

---

# Application Tier Security

Application instances are deployed inside private subnets.

Security controls:

* No public IP addresses
* No direct inbound internet access
* Traffic accepted only from the ALB security group

Allowed inbound communication:

```text
ALB Security Group
        |
        v
Application Security Group

HTTP 80
```

Benefits:

* Reduced attack surface
* Controlled application access
* Network segmentation

---

# Database Security

Aurora MySQL is deployed in private database subnets.

Security controls:

* Public accessibility disabled
* No internet route
* Access restricted through security groups

Allowed communication:

```text
Application Security Group
          |
          v
Database Security Group

TCP 3306
```

Blocked:

* Internet access
* Direct user connections
* Public database exposure

---

# Security Group Strategy

Security groups follow least privilege access.

## Load Balancer Security Group

Inbound:

| Source   | Protocol | Port |
| -------- | -------- | ---- |
| Internet | HTTP     | 80   |

Outbound:

| Destination      | Purpose                     |
| ---------------- | --------------------------- |
| Application Tier | Forward application traffic |

---

## Application Security Group

Inbound:

| Source             | Protocol | Port |
| ------------------ | -------- | ---- |
| ALB Security Group | HTTP     | 80   |

Outbound:

| Destination     | Purpose                |
| --------------- | ---------------------- |
| Aurora Database | Database communication |
| NAT Gateway     | Software updates       |

---

## Database Security Group

Inbound:

| Source                     | Protocol | Port |
| -------------------------- | -------- | ---- |
| Application Security Group | MySQL    | 3306 |

Database access is controlled using security group references instead of broad CIDR ranges.

---

# Identity and Access Management

## EC2 IAM Role

Application instances use:

* IAM Role
* Instance Profile

This allows AWS service access without storing credentials on EC2 instances.

Benefits:

* Temporary AWS credentials
* Automatic credential rotation
* No hardcoded access keys

---

# Administrative Access

Traditional SSH access is intentionally avoided.

Not implemented:

```text
Internet
    |
    v
SSH Port 22
    |
    v
EC2 Instance
```

Reason:

Opening SSH increases administrative attack surface.

Preferred access method:

```text
Administrator
      |
      v
AWS Systems Manager Session Manager
      |
      v
Private EC2 Instance
```

Benefits:

* No inbound SSH required
* IAM-controlled access
* Session auditing support

---

# Credential Management

The repository does not store secrets.

Not committed:

```text
AWS Access Keys
Database passwords
Private keys
Configuration secrets
```

Development credentials are provided through environment variables.

Example:

```bash
export DB_MASTER_USERNAME=<username>
export DB_MASTER_PASSWORD=<password>
```

Production recommendation:

Use AWS Secrets Manager for:

* Database credentials
* Application secrets
* Automatic rotation

---

# Encryption Considerations

## Data in Transit

Current:

* Internal AWS communication through private networking

Production enhancement:

* HTTPS listener on Application Load Balancer
* TLS certificate using AWS Certificate Manager

Recommended:

```text
User
 |
HTTPS
 |
ALB
 |
Application
```

---

## Data at Rest

Production recommendations:

Enable encryption for:

* Aurora storage
* EBS volumes
* Database backups
* Application secrets

AWS Key Management Service (KMS) should be used for encryption key management.

---

# Monitoring and Detection

Recommended production monitoring:

## CloudTrail

Purpose:

* API activity logging
* Security auditing
* Change tracking

## CloudWatch

Purpose:

* Infrastructure monitoring
* Operational alerts
* Application visibility

## AWS Config

Purpose:

* Configuration compliance
* Security drift detection

---

# Security Improvements Roadmap

Future enhancements:

* HTTPS using AWS Certificate Manager
* AWS WAF integration
* Secrets Manager implementation
* CloudTrail security auditing
* AWS Config compliance checks
* GuardDuty threat detection
* VPC Flow Logs
* Automated vulnerability scanning
* CI/CD security checks

---

# Security Summary

Security controls implemented:

| Area                  | Implementation                   |
| --------------------- | -------------------------------- |
| Network isolation     | Public/private subnet separation |
| Access control        | Security group references        |
| Compute access        | IAM roles                        |
| Administrative access | No public SSH exposure           |
| Database protection   | Private Aurora deployment        |
| Credential handling   | No hardcoded secrets             |

The architecture reduces exposure by allowing only required communication paths between services while maintaining operational access through AWS-native security mechanisms.