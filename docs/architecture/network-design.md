# Network Design

## Overview

This document describes the networking architecture used by the AWS Production Web Platform.

The environment is deployed within a dedicated Amazon VPC and follows a multi-tier network design that separates public-facing resources, application services, and database services.

Network design goals:

* Network isolation
* High availability
* Controlled internet exposure
* Secure east-west communication
* Production-style subnet segmentation

---

# Network Architecture

The platform is deployed across two Availability Zones within a single AWS Region.

Architecture:

```text
Internet
    |
    v
Internet Gateway
    |
    v
Public Subnets
    |
    v
Application Load Balancer
    |
    v
Private Application Subnets
    |
    v
Private Database Subnets
```

---

# VPC Design

The environment uses a dedicated Virtual Private Cloud (VPC).

| Item               | Value                  |
| ------------------ | ---------------------- |
| Region             | us-east-1              |
| VPC CIDR           | 10.0.0.0/16            |
| Availability Zones | us-east-1a, us-east-1b |

---

## CIDR Strategy

VPC CIDR:

```text
10.0.0.0/16
```

The /16 address space was selected because it:

* Provides sufficient address capacity
* Supports future subnet growth
* Simplifies subnet allocation
* Follows common enterprise networking practices

Available address capacity:

```text
65,536 IP addresses
```

---

# Availability Zone Design

Resources are distributed across:

```text
us-east-1a
us-east-1b
```

Benefits:

* Fault isolation
* Improved availability
* Reduced single points of failure
* Support for Multi-AZ application deployment

If a single Availability Zone becomes unavailable, application resources can continue operating within the remaining Availability Zone.

---

# Subnet Design

The environment uses six subnets.

## Public Subnets

| Subnet            | CIDR        | Availability Zone | Purpose             |
| ----------------- | ----------- | ----------------- | ------------------- |
| public-subnet-az1 | 10.0.1.0/24 | us-east-1a        | ALB and NAT Gateway |
| public-subnet-az2 | 10.0.2.0/24 | us-east-1b        | ALB and NAT Gateway |

Purpose:

* Internet-facing resources
* Inbound traffic entry point
* Outbound NAT services

---

## Private Application Subnets

| Subnet                 | CIDR         | Availability Zone | Purpose             |
| ---------------------- | ------------ | ----------------- | ------------------- |
| private-app-subnet-az1 | 10.0.11.0/24 | us-east-1a        | Application compute |
| private-app-subnet-az2 | 10.0.12.0/24 | us-east-1b        | Application compute |

Purpose:

* EC2 application instances
* Auto Scaling Group placement
* No direct internet exposure

---

## Private Database Subnets

| Subnet                | CIDR         | Availability Zone | Purpose              |
| --------------------- | ------------ | ----------------- | -------------------- |
| private-db-subnet-az1 | 10.0.21.0/24 | us-east-1a        | Aurora database tier |
| private-db-subnet-az2 | 10.0.22.0/24 | us-east-1b        | Aurora database tier |

Purpose:

* Database isolation
* Restricted access
* No internet connectivity

---

# Routing Design

## Public Route Table

Public subnets use:

```text
0.0.0.0/0 → Internet Gateway
```

Purpose:

* Internet access
* Public application entry point
* NAT Gateway connectivity

---

## Private Application Route Tables

Private application subnets use:

```text
0.0.0.0/0 → NAT Gateway
```

Purpose:

* Software updates
* Package downloads
* External API communication

Inbound internet traffic is not permitted.

---

## Database Route Tables

Database subnets do not require direct internet connectivity.

Database resources communicate only with application resources inside the VPC.

---

# Internet Connectivity Design

## Internet Gateway

The VPC includes an Internet Gateway.

Purpose:

* Public internet access
* Load balancer connectivity
* NAT Gateway connectivity

Traffic flow:

```text
Internet
    |
    v
Internet Gateway
    |
    v
Public Subnets
```

---

## NAT Gateway Design

Each Availability Zone contains a dedicated NAT Gateway.

Architecture:

```text
Private App Subnet AZ-A
          |
          v
     NAT Gateway A

Private App Subnet AZ-B
          |
          v
     NAT Gateway B
```

Benefits:

* Outbound internet access
* Private instance protection
* Improved availability

Tradeoff:

* Increased monthly cost compared to a single NAT Gateway design

---

# Traffic Flow

## Inbound Traffic

User request:

```text
Internet
    |
    v
Application Load Balancer
    |
    v
EC2 Application Instance
```

The Application Load Balancer is the only publicly reachable application endpoint.

---

## Application to Database Traffic

Application request:

```text
Application Instance
          |
          v
Aurora MySQL
```

Database access remains private within the VPC.

---

## Outbound Traffic

Application outbound traffic:

```text
EC2 Instance
     |
     v
NAT Gateway
     |
     v
Internet
```

This allows software updates and external service communication while preventing inbound internet access.

---

# Network Security Intent

The network architecture follows a defense-in-depth model.

Security goals:

* Minimize public exposure
* Isolate application and database tiers
* Restrict communication paths
* Support least-privilege networking

Traffic restrictions:

```text
Internet
     |
     v
ALB Security Group
     |
     v
Application Security Group
     |
     v
Database Security Group
```

Only required communication paths are allowed.

---

# Design Decisions

## Why Private Application Subnets?

Application servers do not require direct internet exposure.

Benefits:

* Reduced attack surface
* Improved security posture
* Better alignment with production architectures

---

## Why Private Database Subnets?

Databases should never be directly accessible from the internet.

Benefits:

* Reduced exposure risk
* Controlled access model
* Improved compliance with security best practices

---

## Why Multi-AZ Networking?

Multi-AZ deployment improves resilience.

Benefits:

* Availability during AZ failures
* Better fault isolation
* Support for highly available services

---

# Future Enhancements

Potential networking improvements:

* VPC Flow Logs
* Transit Gateway integration
* AWS Network Firewall
* IPv6 support
* PrivateLink integration
* VPC endpoints for AWS services

---

# Summary

The network architecture separates public, application, and database resources into dedicated subnet tiers across multiple Availability Zones.

The design prioritizes:

* Security
* Availability
* Controlled internet access
* Network segmentation
* Production-style AWS networking practices