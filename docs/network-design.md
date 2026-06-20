# Network Design

## Overview

This project uses a custom Amazon VPC to host a production-style web application across two Availability Zones.
The network is designed to separate public-facing resources, private application resources, and private database resources.

## VPC

| Item | Value |
|---|---|
| VPC CIDR | 10.0.0.0/16 |
| Region | us-east-1 |
| Availability Zones | us-east-1a, us-east-1b |

## Subnet Plan

| Subnet Name | CIDR Block | Availability Zone | Purpose |
|---|---|---|---|
| public-subnet-az1 | 10.0.1.0/24 | us-east-1a | ALB and NAT Gateway |
| public-subnet-az2 | 10.0.2.0/24 | us-east-1b | ALB and NAT Gateway |
| private-app-subnet-az1 | 10.0.11.0/24 | us-east-1a | EC2 application instances |
| private-app-subnet-az2 | 10.0.12.0/24 | us-east-1b | EC2 application instances |
| private-db-subnet-az1 | 10.0.21.0/24 | us-east-1a | RDS database |
| private-db-subnet-az2 | 10.0.22.0/24 | us-east-1b | RDS database |

## Design Decisions

### Why 10.0.0.0/16?

The VPC uses `10.0.0.0/16` because it provides a large private address space, supports future subnet expansion, and follows a common enterprise networking pattern.

### Why two Availability Zones?

Using two Availability Zones improves availability by allowing the application to continue running if one Availability Zone has issues.

### Why separate public, private app, and private database subnets?

Separating resources by function improves security and makes routing easier to manage.

- Public subnets contain internet-facing resources.
- Private app subnets contain EC2 instances that should not be directly reachable from the internet.
- Private database subnets contain RDS resources that should only be reachable by the application tier.

## Routing Plan

- Public subnets route outbound internet traffic through the Internet Gateway.
- Private app subnets route outbound internet traffic through a NAT Gateway.
- Private database subnets do not have direct internet access.

## Security Intent

- The Application Load Balancer will accept inbound web traffic from the internet.
- EC2 instances will only accept inbound traffic from the Application Load Balancer.
- RDS will only accept inbound database traffic from the EC2 security group.