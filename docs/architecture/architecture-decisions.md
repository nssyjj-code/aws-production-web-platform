# Architecture Decisions

## Overview

This document records the major architecture decisions made for the AWS Production Web Platform.

The goal is to document not only what was built, but why specific AWS services, network patterns, and operational designs were selected.

Each decision includes:

* Context
* Decision
* Reasoning
* Alternatives considered
* Tradeoffs

---

# ADR-001: Use a Three-Tier Architecture

## Context

The project required a production-style web platform that separates public traffic handling, application compute, and database services.

## Decision

Use a three-tier architecture:

```text
Public Tier       → Application Load Balancer
Application Tier  → EC2 instances in Auto Scaling Group
Database Tier     → Aurora MySQL
```

## Reasoning

This pattern improves separation of concerns and reflects common production cloud architecture.

## Alternatives Considered

| Alternative                             | Reason Not Selected                                                                    |
| --------------------------------------- | -------------------------------------------------------------------------------------- |
| Single EC2 instance with local database | Too simple and not production-oriented                                                 |
| Serverless-only architecture            | Valid option, but not aligned with the networking and operations goals of this project |
| Public EC2 application instances        | Larger attack surface                                                                  |

## Tradeoffs

This design is more complex and more expensive than a single-instance architecture, but it better demonstrates real-world cloud engineering practices.

---

# ADR-002: Use Multi-AZ Networking

## Context

The platform should avoid depending on a single Availability Zone.

## Decision

Deploy public, private application, and private database subnets across two Availability Zones.

## Reasoning

Multi-AZ design improves availability and supports fault isolation.

## Alternatives Considered

| Alternative          | Reason Not Selected                                                   |
| -------------------- | --------------------------------------------------------------------- |
| Single-AZ deployment | Lower cost, but creates single-AZ failure risk                        |
| Three-AZ deployment  | More resilient, but unnecessary for the project scope and cost target |

## Tradeoffs

Multi-AZ networking increases complexity and cost, especially with NAT Gateways, but provides a more production-aligned architecture.

---

# ADR-003: Place Application Instances in Private Subnets

## Context

Application instances need to serve user traffic but do not require direct internet exposure.

## Decision

Deploy EC2 application instances into private application subnets.

## Reasoning

Traffic enters through the Application Load Balancer. EC2 instances only accept traffic from the ALB security group.

## Alternatives Considered

| Alternative                  | Reason Not Selected                 |
| ---------------------------- | ----------------------------------- |
| Public EC2 instances         | Increases attack surface            |
| Bastion host with SSH access | Adds operational overhead           |
| Fully private access only    | Not suitable for public web traffic |

## Tradeoffs

Private subnets require NAT Gateways for outbound internet access, increasing cost, but improving security posture.

---

# ADR-004: Use an Application Load Balancer

## Context

The application requires public HTTP access and traffic distribution across multiple EC2 instances.

## Decision

Use an internet-facing Application Load Balancer.

## Reasoning

The ALB provides:

* Public traffic entry point
* Target group health checks
* Distribution across instances
* Integration with Auto Scaling

## Alternatives Considered

| Alternative                | Reason Not Selected                                                    |
| -------------------------- | ---------------------------------------------------------------------- |
| Network Load Balancer      | Better for TCP/UDP, but unnecessary for HTTP web traffic               |
| Elastic IP directly on EC2 | Not highly available                                                   |
| CloudFront only            | Requires an origin and does not replace load balancing for EC2 targets |

## Tradeoffs

An ALB adds cost, but provides production-style routing, health checks, and availability.

---

# ADR-005: Use Auto Scaling Group for EC2 Instances

## Context

Application compute should be replaceable and able to scale horizontally.

## Decision

Deploy EC2 instances through an Auto Scaling Group using a Launch Template.

## Reasoning

Auto Scaling provides:

* Instance replacement
* Desired capacity enforcement
* Multi-AZ compute placement
* Integration with target groups

## Alternatives Considered

| Alternative                     | Reason Not Selected                                            |
| ------------------------------- | -------------------------------------------------------------- |
| Manually launched EC2 instances | Not repeatable or self-healing                                 |
| ECS/Fargate                     | Strong option, but not the focus of this EC2-based platform    |
| Lambda                          | Not aligned with the project’s infrastructure operations goals |

## Tradeoffs

Auto Scaling adds configuration complexity, but significantly improves operational reliability.

---

# ADR-006: Use Aurora MySQL for Database Layer

## Context

The project required a managed relational database in a private database tier.

## Decision

Use Amazon Aurora MySQL.

## Reasoning

Aurora demonstrates a managed production database pattern with MySQL compatibility.

## Alternatives Considered

| Alternative            | Reason Not Selected                                                               |
| ---------------------- | --------------------------------------------------------------------------------- |
| MySQL installed on EC2 | Higher operational burden                                                         |
| Standard RDS MySQL     | Valid option, but Aurora better demonstrates enterprise-managed database patterns |
| DynamoDB               | NoSQL service; not aligned with relational database requirement                   |

## Tradeoffs

Aurora can cost more than simpler options, but reduces database administration overhead and better supports high availability patterns.

---

# ADR-007: Use NAT Gateways for Private Subnet Outbound Access

## Context

Private application instances require outbound internet access for updates, package downloads, and external service calls.

## Decision

Use NAT Gateways in public subnets.

## Reasoning

NAT Gateways allow private instances to initiate outbound internet connections without allowing inbound internet traffic.

## Alternatives Considered

| Alternative                          | Reason Not Selected                          |
| ------------------------------------ | -------------------------------------------- |
| Public IP addresses on EC2 instances | Increases exposure                           |
| NAT instance                         | Requires patching and operational management |
| No outbound internet access          | Too restrictive for application operations   |

## Tradeoffs

NAT Gateways are a major cost driver, but they are a production-aligned managed service.

---

# ADR-008: Use Security Group Referencing

## Context

The platform requires controlled communication between tiers.

## Decision

Use security group references instead of broad CIDR-based access where possible.

Traffic model:

```text
Internet → ALB Security Group → Application Security Group → Database Security Group
```

## Reasoning

Security group references reduce reliance on static IP ranges and support least-privilege access between layers.

## Alternatives Considered

| Alternative            | Reason Not Selected                              |
| ---------------------- | ------------------------------------------------ |
| Open CIDR rules        | Less secure                                      |
| Public database access | Not acceptable for production-style architecture |
| Manual IP allowlists   | Harder to maintain                               |

## Tradeoffs

Security group references require careful dependency ordering during deployment and teardown.

---

# ADR-009: Use AWS CLI Automation

## Context

The project needed repeatable infrastructure deployment while reinforcing hands-on understanding of AWS services.

## Decision

Use AWS CLI scripts for deployment and teardown automation.

## Reasoning

AWS CLI automation demonstrates:

* Service-level AWS knowledge
* Resource dependency awareness
* Repeatable deployment processes
* Infrastructure lifecycle management

## Alternatives Considered

| Alternative               | Reason Not Selected                                                        |
| ------------------------- | -------------------------------------------------------------------------- |
| Terraform                 | Strong production option, but abstracts some service-level learning        |
| CloudFormation            | Strong AWS-native option, but not the focus of this CLI automation project |
| Manual console deployment | Not repeatable or portfolio-worthy                                         |

## Tradeoffs

AWS CLI scripts require more manual dependency management than Terraform or CloudFormation. This project intentionally uses CLI automation to demonstrate understanding of AWS resource relationships.

---

# ADR-010: Use Automated Destroy Process

## Context

Development environments can create unnecessary cost if left running.

## Decision

Implement a dependency-aware destroy script.

## Reasoning

The destroy process reduces cost and demonstrates full infrastructure lifecycle ownership.

The script handles resource cleanup in dependency order, including:

* Auto Scaling Group
* ALB listeners
* Application Load Balancer
* Target Group
* Aurora resources
* NAT Gateways
* Route tables
* Security groups
* Subnets
* Internet Gateway
* VPC

## Alternatives Considered

| Alternative             | Reason Not Selected       |
| ----------------------- | ------------------------- |
| Manual console cleanup  | Error-prone               |
| Leave resources running | Unnecessary cost          |
| Delete VPC first        | Fails due to dependencies |

## Tradeoffs

Destroy automation adds development effort but improves operational discipline and cost control.

---

# Summary

These architecture decisions reflect a balance between:

* Security
* Availability
* Cost
* Operational complexity
* Portfolio learning value

The project intentionally favors production-style design patterns while documenting tradeoffs and future improvements.