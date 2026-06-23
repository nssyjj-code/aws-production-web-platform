# Architecture

## Overview

This project implements a highly available three-tier web platform in AWS spanning multiple Availability Zones. The environment is deployed entirely through AWS CLI automation and consists of a public load balancing tier, a private application tier, and a private database tier.

### Architecture Goals

* High availability across multiple Availability Zones
* Separation of network tiers using private subnets
* Horizontal application scaling through Auto Scaling Groups
* Secure database isolation
* Full environment lifecycle automation (deployment and teardown)
* Production-oriented networking and security practices

---

## Network Architecture

The environment is deployed within a dedicated VPC using the CIDR range:

```text
10.0.0.0/16
```

Resources are distributed across two Availability Zones to improve fault tolerance and reduce single points of failure.

### Public Tier

Public subnets host internet-facing infrastructure:

* Application Load Balancer (ALB)
* NAT Gateways

These resources receive inbound internet traffic and provide controlled access to internal services.

### Application Tier

Application servers are deployed into private subnets and managed by an Auto Scaling Group.

Characteristics:

* No public IP addresses
* No direct inbound internet access
* Traffic accepted only from the Application Load Balancer
* Outbound internet access provided through NAT Gateways

### Database Tier

Amazon Aurora MySQL is deployed into dedicated private database subnets.

Characteristics:

* Not publicly accessible
* Accessible only from application servers
* Isolated from direct internet traffic
* Deployed across multiple Availability Zones

---

## Traffic Flow

```text
Internet
    ↓
Application Load Balancer
    ↓
Target Group
    ↓
Auto Scaling Group
    ↓
EC2 Application Instances
    ↓
Aurora MySQL
```

---

## Security Design

The environment follows a layered security model.

### Load Balancer Security Group

Allowed:

* HTTP (80) from the internet

### Application Security Group

Allowed:

* HTTP (80) from the ALB Security Group

Denied:

* Direct internet access

### Database Security Group

Allowed:

* MySQL (3306) from the Application Security Group

Denied:

* Public access

---

## High Availability Design

High availability is achieved through:

* Multi-AZ subnet deployment
* Multiple NAT Gateways
* Application Load Balancer spanning both Availability Zones
* Auto Scaling Group deployment across Availability Zones
* Aurora cluster deployment across multiple Availability Zones

If a single Availability Zone becomes unavailable, application traffic can continue to be served from healthy resources in the remaining zone.

---

## Design Decisions

### Why Private Application Subnets?

Application instances do not require direct internet exposure. Restricting them to private subnets reduces attack surface and follows AWS security best practices.

### Why Separate NAT Gateways?

A NAT Gateway is deployed in each Availability Zone to reduce cross-AZ dependencies and improve resilience during infrastructure failures.

### Why Aurora MySQL?

Aurora provides managed database operations, automated backups, and high availability while maintaining MySQL compatibility.

### Why an Application Load Balancer?

The ALB distributes traffic across multiple instances and integrates directly with Auto Scaling Groups and health checks.

---

## Operational Considerations

The platform includes automation for the complete infrastructure lifecycle:

* Environment deployment
* Resource configuration
* Service validation
* Environment teardown

Destroy operations include dependency-aware cleanup to ensure resources are removed in the correct order and AWS dependency constraints are respected.