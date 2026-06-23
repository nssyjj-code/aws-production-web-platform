# Cost Optimization

## Overview

This document describes the cost considerations, optimization strategies, and architectural tradeoffs for the AWS Production Web Platform.

The environment is designed to demonstrate production-style cloud architecture while maintaining awareness of operational costs.

Cost optimization goals:

* Understand primary AWS cost drivers
* Avoid unnecessary resource usage
* Right-size infrastructure based on workload requirements
* Balance availability, reliability, security, and cost
* Implement lifecycle management to reduce unused resources

This project follows concepts from the AWS Well-Architected Framework Cost Optimization pillar.

---

# Cost Design Philosophy

This project intentionally prioritizes learning production architecture patterns over creating the lowest-cost AWS environment.

Some resources increase cost but were selected because they represent real-world enterprise designs.

Examples:

* Multi-AZ networking
* Multiple NAT Gateways
* Managed relational database
* Application Load Balancer
* Auto Scaling architecture

Lower-cost alternatives are documented where appropriate.

---

# Primary Cost Drivers

| AWS Service               | Purpose                        | Cost Consideration                            |
| ------------------------- | ------------------------------ | --------------------------------------------- |
| Application Load Balancer | Public traffic distribution    | Hourly usage and load balancer capacity units |
| EC2                       | Application compute layer      | Instance runtime, size, and storage           |
| Auto Scaling Group        | Compute availability           | Controls number of running instances          |
| Aurora MySQL              | Managed database layer         | Instance runtime, storage, backups, and I/O   |
| NAT Gateway               | Private subnet outbound access | Hourly runtime and processed data             |
| Elastic Block Store       | EC2 storage                    | Provisioned storage capacity                  |
| Data Transfer             | Network communication          | Cross-AZ and internet traffic                 |

---

# Compute Cost Optimization

## EC2 Auto Scaling

The application tier uses EC2 instances managed by an Auto Scaling Group.

Configuration:

```text
Minimum Capacity: 2
Desired Capacity: 2
Maximum Capacity: 4
```

## Cost Benefits

Auto Scaling helps:

* Match capacity with application demand
* Prevent unnecessary over-provisioning
* Replace unhealthy resources automatically

## Production Improvements

Additional optimization strategies:

* Analyze utilization metrics before resizing
* Use Compute Savings Plans for predictable workloads
* Use Reserved Instances for stable long-term workloads
* Evaluate AWS Graviton processors for better price/performance
* Implement scaling policies based on application metrics

---

# Networking Cost Optimization

## NAT Gateway Architecture Decision

### Current Design

This environment deploys NAT Gateways across multiple Availability Zones.

Architecture:

```text
Private Subnet AZ-A
        |
        v
NAT Gateway AZ-A


Private Subnet AZ-B
        |
        v
NAT Gateway AZ-B
```

## Reason

This design improves availability by avoiding dependency on a single Availability Zone.

If one Availability Zone fails, private resources in the remaining Availability Zone maintain outbound connectivity.

## Cost Tradeoff

Multi-AZ NAT Gateways increase hourly cost compared to using a single NAT Gateway.

Alternative development design:

```text
Private Subnet AZ-A
        |
        |
        v
Single NAT Gateway

        ^
        |
Private Subnet AZ-B
```

Benefits:

* Lower monthly cost
* Fewer resources

Tradeoff:

* Creates single-AZ dependency
* Less resilient architecture

Decision:

Production reliability was prioritized over minimum cost.

---

# Database Cost Optimization

## Aurora MySQL

Aurora was selected to demonstrate managed database architecture.

Benefits:

* Managed database operations
* Automated backups
* High availability capabilities
* MySQL compatibility

## Cost Considerations

Primary database costs:

* Database instance runtime
* Storage usage
* Backup retention
* Database I/O activity

---

## Development Optimization

For temporary environments:

* Stop database resources when unused
* Use smaller database instances
* Reduce backup retention periods
* Destroy environments after testing

---

## Production Optimization

For production workloads:

* Monitor CPU utilization
* Monitor connection usage
* Right-size database instances
* Evaluate Aurora Serverless for variable workloads
* Review storage growth trends

---

# Storage Optimization

## Amazon EBS

EC2 instances use EBS-backed storage.

Optimization practices:

* Select appropriate volume types
* Remove unattached volumes
* Monitor disk utilization
* Avoid over-provisioning capacity

General Purpose SSD storage provides a balance between:

* Cost
* Performance
* Reliability

---

# Development vs Production Cost Strategy

Different environments require different cost decisions.

| Component    | Development Approach   | Production Approach          |
| ------------ | ---------------------- | ---------------------------- |
| NAT Gateway  | Single NAT possible    | Multi-AZ NAT recommended     |
| EC2          | Smaller instances      | Right-sized capacity         |
| Auto Scaling | Lower minimum capacity | Availability-focused scaling |
| Aurora       | Smaller instances      | Performance-based sizing     |
| Backups      | Short retention        | Business requirement based   |
| Monitoring   | Basic metrics          | Full observability           |

---

# Resource Lifecycle Management

Unused cloud resources create unnecessary costs.

This project includes automated teardown:

```bash
./scripts/cleanup/destroy-environment.sh
```

The destroy process removes:

* Application Load Balancer
* Target Groups
* Auto Scaling Groups
* EC2 resources
* Aurora resources
* NAT Gateways
* Elastic IPs
* Networking resources
* IAM resources

The cleanup process prevents development environments from running when not needed.

---

# Resource Tagging Strategy

Resource tagging improves cost visibility and governance.

Recommended tags:

```text
Project=aws-production-web-platform
Environment=development
ManagedBy=aws-cli
Owner=cloud-engineering
```

Benefits:

* Cost allocation tracking
* Resource ownership
* Automation targeting
* Governance reporting

---

# Cost Monitoring Strategy

Production environments should include active cost monitoring.

## AWS Budgets

Used for:

* Monthly spending limits
* Cost notifications
* Usage tracking

## Cost Explorer

Used for:

* Service cost analysis
* Usage trends
* Optimization opportunities

## Cost Anomaly Detection

Used for:

* Unexpected spending changes
* Abnormal resource usage
* Early cost alerts

---

# Cost Controls Implemented

Implemented in this project:

* Automated environment teardown
* Controlled resource provisioning
* Private networking design
* Auto Scaling capacity management
* Resource organization through naming standards

Recommended future improvements:

* AWS Budget alerts
* Automated shutdown schedules
* Infrastructure as Code cost estimation
* CI/CD cost validation
* Resource utilization dashboards

---

# Architecture Cost Tradeoffs

## Availability vs Cost

Decision:

Use multiple Availability Zones.

Benefit:

Improves fault tolerance.

Tradeoff:

Additional infrastructure cost.

---

## Managed Services vs Self-Managed Services

Decision:

Use Aurora instead of self-managed MySQL.

Benefit:

Reduced operational overhead.

Tradeoff:

Higher service cost.

---

## Private Infrastructure vs Simplicity

Decision:

Use private subnets with NAT Gateways.

Benefit:

Improved security posture.

Tradeoff:

Additional networking cost.

---

# Summary

The architecture intentionally balances production design practices with cost awareness.

The objective is not only to minimize AWS spending, but to understand engineering tradeoffs between:

* Cost
* Security
* Availability
* Operational complexity

Cost optimization is treated as an ongoing operational responsibility rather than a one-time design decision.