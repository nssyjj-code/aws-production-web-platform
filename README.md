# AWS Production Web Platform

## Overview

This project builds a production-style AWS web platform designed to demonstrate core cloud engineering skills, including networking, security, compute, monitoring, automation, and high availability.

The goal is to design and deploy an AWS environment similar to what a small company might use to host a secure and scalable web application.

## Project Goals

- Build a custom AWS VPC with public and private subnets
- Deploy compute resources behind a load balancer
- Implement security best practices using IAM roles and security groups
- Add monitoring, logging, and alerting with CloudWatch
- Automate deployment using AWS CLI and Bash
- Document deployment, troubleshooting, cost, and security decisions
- Simulate real-world operational scenarios such as instance failure and recovery

## Architecture

This project will include:

- VPC across multiple Availability Zones
- Public and private subnets
- Internet Gateway and NAT Gateway
- Application Load Balancer
- EC2 instances
- Auto Scaling Group
- RDS database
- S3 storage
- CloudWatch monitoring
- SNS alerts
- IAM roles
- Systems Manager access

## Technologies Used

- AWS
- AWS CLI
- Bash
- EC2
- VPC
- ALB
- Auto Scaling
- RDS
- S3
- IAM
- CloudWatch
- SNS
- Systems Manager

## Repository Structure

```text
aws-production-web-platform/
├── architecture/
├── assets/
├── config/
├── docs/
├── monitoring/
├── screenshots/
└── scripts/
```

## Project Status

In progress.

Current phase: project planning and architecture design.

## Future Improvements

- Rebuild using CloudFormation
- Rebuild using Terraform
- Add GitHub Actions CI/CD
- Containerize the application
- Deploy with ECS or EKS
- Add advanced observability tooling