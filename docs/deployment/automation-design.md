# Automation Design

## Overview

This document describes the design approach behind the AWS CLI automation used to deploy, validate, and destroy the AWS Production Web Platform.

The automation was designed to provide repeatable infrastructure lifecycle management while demonstrating how AWS resources depend on each other during provisioning and teardown.

Automation goals:

* Repeatable deployments
* Consistent configuration management
* Dependency-aware resource creation
* Safe environment cleanup
* Operational troubleshooting visibility

---

# Automation Structure

Project automation is organized by lifecycle stage.

```text
scripts/

├── deploy/
│   └── deploy.sh

├── validation/
│   └── verify-environment.sh

└── cleanup/
    └── destroy-environment.sh
```

Each script focuses on a specific operational responsibility:

| Script                 | Purpose                           |
| ---------------------- | --------------------------------- |
| deploy.sh              | Creates AWS infrastructure        |
| verify-environment.sh  | Validates deployed resources      |
| destroy-environment.sh | Removes AWS infrastructure safely |

---

# Configuration Management

Deployment settings are separated from automation logic.

Configuration file:

```text
config/environment.conf
```

The deployment scripts load configuration values at runtime.

Benefits:

* Avoids hardcoded resource values
* Allows environment customization
* Improves maintainability
* Separates configuration from execution logic

Example:

```bash
source config/environment.conf
```

---

# Deployment Automation Design

The deployment script follows a dependency-based execution model.

AWS resources are created only after their dependencies exist.

Deployment order:

```text
VPC
 |
 v
Subnets
 |
 v
Internet Gateway
 |
 v
Route Tables
 |
 v
NAT Gateways
 |
 v
Security Groups
 |
 v
IAM
 |
 v
Launch Template
 |
 v
Target Group
 |
 v
Application Load Balancer
 |
 v
Auto Scaling Group
 |
 v
Aurora Database
```

---

# Why Dependency Ordering Matters

AWS services depend on other resources existing before creation.

Examples:

A subnet cannot exist without:

```text
VPC
```

An Auto Scaling Group requires:

```text
Launch Template
        +
Subnets
        +
Target Group
```

Aurora requires:

```text
DB Subnet Group
        +
Security Group
```

The automation handles this ordering to prevent deployment failures.

---

# Script Design Pattern

Scripts use a modular function-based structure.

Example:

```bash
main() {
    create_network
    create_security
    create_compute
    create_database
    validate_deployment
}
```

Benefits:

* Easier troubleshooting
* Better readability
* Individual component testing
* Cleaner maintenance

---

# Error Handling Strategy

Scripts use strict Bash execution settings.

```bash
set -euo pipefail
```

Purpose:

## -e

Exit immediately when a command fails.

Prevents continuing after failed infrastructure creation.

## -u

Detect undefined variables.

Prevents accidental deployment using missing configuration.

## pipefail

Detect failures inside command pipelines.

Improves reliability of automation logic.

---

# AWS CLI Resource Discovery

Automation avoids relying only on manually provided IDs.

Where possible, resources are discovered dynamically.

Example:

```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=<name>"
```

Benefits:

* More flexible automation
* Easier troubleshooting
* Reduced manual input

---

# Validation Automation

After deployment, validation checks confirm resources were created successfully.

Validation includes:

Networking:

* VPC exists
* Subnets exist
* Routes configured

Compute:

* Auto Scaling Group exists
* Instances running
* Target health checks passing

Database:

* Aurora cluster available

Security:

* Expected security groups exist

---

# Destroy Automation Design

The destroy process follows reverse dependency ordering.

Resources must be deleted safely because AWS prevents removing resources with active dependencies.

Cleanup order:

```text
Auto Scaling Group
 |
 v
ALB Listeners
 |
 v
Application Load Balancer
 |
 v
Target Group
 |
 v
Aurora Resources
 |
 v
Launch Templates
 |
 v
IAM Resources
 |
 v
NAT Gateways
 |
 v
Route Tables
 |
 v
Security Groups
 |
 v
Subnets
 |
 v
Internet Gateway
 |
 v
VPC
```

---

# Dependency Issue Example

During development, target group deletion failed because it was still attached to an Application Load Balancer listener.

Error:

```text
ResourceInUse:
Target group is currently in use by a listener or rule
```

Resolution:

Destroy automation was updated to remove dependencies first.

Correct order:

```text
Delete Listener
       |
       v
Delete Target Group
```

---

# Idempotency Considerations

Automation is designed to safely handle repeated execution.

Examples:

* Check if resources exist before deletion
* Continue cleanup when resources are already removed
* Validate AWS responses before proceeding

This reduces failures during retries.

---

# Current Implementation Choice

This project intentionally uses AWS CLI automation.

Purpose:

* Understand AWS service relationships
* Practice infrastructure automation fundamentals
* Learn dependency management

---

# Future Production Improvements

A production evolution of this automation could include:

* Terraform migration
* CloudFormation implementation
* CI/CD pipeline execution
* Automated testing
* Deployment approvals
* State management
* Drift detection

---

# Summary

The automation design demonstrates complete infrastructure lifecycle management:

* Provisioning
* Validation
* Operation
* Cleanup

The goal is not only creating AWS resources, but understanding the automation principles used by production infrastructure platforms.