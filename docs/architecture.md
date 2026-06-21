# Architecture

This project implements a three-tier AWS web platform.

## Network Tier

The VPC uses a `10.0.0.0/16` CIDR block and spans two Availability Zones.

Subnets are separated by function:

* Public subnets for the Application Load Balancer and NAT Gateways
* Private application subnets for EC2 instances managed by an Auto Scaling Group
* Private database subnets for Aurora MySQL

## Traffic Flow

```text
Internet
  ↓
Application Load Balancer
  ↓
Target Group
  ↓
Auto Scaling Group / EC2
  ↓
Aurora MySQL
```

## Design Decisions

The platform uses private application subnets so EC2 instances do not receive direct inbound internet traffic.

NAT Gateways are deployed per Availability Zone to reduce cross-AZ dependency and improve availability.

Aurora is deployed in private database subnets and is not publicly accessible.