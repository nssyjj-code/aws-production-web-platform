# AWS Production Web Platform

A production-style AWS infrastructure project built with Bash and the AWS CLI before transitioning to Terraform.

This project provisions a multi-tier, highly available web platform using modular, idempotent deployment scripts and shared helper libraries.

## Architecture

![AWS Production Web Platform Architecture](architecture/architecture-aws-style.svg)

The platform includes:

* Multi-AZ VPC
* Public, private application, and private database subnets
* Internet Gateway
* NAT Gateways per Availability Zone
* Custom route tables
* Layered security groups
* EC2 IAM role and instance profile for SSM access
* Launch Template
* Application Load Balancer
* Target Group
* Auto Scaling Group
* Private Aurora MySQL database

## Features

* Multi-Availability Zone VPC architecture
* Public, private application, and private database subnets
* High availability using NAT Gateways in each Availability Zone
* Layered security groups following least privilege principles
* IAM roles and instance profiles for EC2
* Application Load Balancer with Target Group
* Launch Template and Auto Scaling Group
* Private Amazon Aurora MySQL database
* Modular deployment scripts
* Shared helper libraries for reusable infrastructure functions
* Idempotent deployments that safely re-run existing resources
* Automated deployment and verification scripts
* Configuration-driven environment using a centralized configuration file

## Current Status

Core infrastructure deployment is complete using AWS CLI automation.

## Repository Structure

```text
config/       Shared environment configuration
docs/         Project documentation
diagrams/     Architecture diagrams
monitoring/   Future CloudWatch dashboards and alarms
policies/     IAM trust policies
scripts/      Deployment, verification, destroy, and helper scripts
user-data/    EC2 bootstrap scripts
```

## Deployment

```bash
export DB_MASTER_USERNAME="adminuser"
export DB_MASTER_PASSWORD="Use-A-Strong-Password-Here123!"

./deploy.sh
```

## Verification

```bash
./verify.sh
```

## Security Notes

* No AWS credentials are committed to the repository.
* EC2 instances use IAM roles instead of access keys.
* Application instances are deployed in private subnets.
* Database resources are deployed in private database subnets.
* Security groups follow a layered access model:

  * Internet → ALB
  * ALB → Application
  * Application → Database

## Project Goal

The goal of this repository is to demonstrate production-style cloud engineering practices using AWS CLI before rebuilding the same architecture with Terraform.