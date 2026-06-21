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

```mermaid
flowchart TB
    Internet((Internet)) --> IGW[Internet Gateway]

    subgraph VPC["VPC: 10.0.0.0/16"]
        IGW --> ALB[Application Load Balancer<br/>Public Subnets]

        subgraph AZ1["Availability Zone: us-east-1a"]
            PubA["Public Subnet AZ1<br/>10.0.1.0/24<br/>NAT Gateway A"]
            AppA["Private App Subnet AZ1<br/>10.0.11.0/24<br/>EC2 Instance"]
            DbA["Private DB Subnet AZ1<br/>10.0.21.0/24"]
        end

        subgraph AZ2["Availability Zone: us-east-1b"]
            PubB["Public Subnet AZ2<br/>10.0.2.0/24<br/>NAT Gateway B"]
            AppB["Private App Subnet AZ2<br/>10.0.12.0/24<br/>EC2 Instance"]
            DbB["Private DB Subnet AZ2<br/>10.0.22.0/24"]
        end

        ALB --> TG[Target Group<br/>HTTP :80]

        TG --> ASG[Auto Scaling Group<br/>Desired: 2 | Min: 2 | Max: 4]

        ASG --> AppA
        ASG --> AppB

        AppA --> Aurora[Aurora MySQL Cluster<br/>Private Database Tier]
        AppB --> Aurora

        Aurora --> DbA
        Aurora --> DbB

        AppA -. Outbound Internet .-> PubA
        AppB -. Outbound Internet .-> PubB
    end
```