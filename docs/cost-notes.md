# Cost Considerations

This project provisions production-style AWS infrastructure. Some resources incur charges while they are running.

## Resources That Generate Ongoing Charges

The following resources continue to incur costs after deployment:

* NAT Gateways
* Elastic IP addresses attached to NAT Gateways
* Application Load Balancer
* EC2 instances
* Aurora MySQL cluster and writer instance
* EBS volumes created by the Launch Template

## Recommended Workflow

Deploy the environment only when actively testing or developing.

After testing is complete:

```bash
./destroy.sh
```

This removes all provisioned infrastructure and helps minimize AWS charges.

## Cost Optimization Decisions

Several design choices were intentionally made to balance production practices with cost awareness.

### Instance Sizes

* EC2: `t3.micro`
* Aurora Writer: `db.t3.medium`

These sizes provide sufficient capacity for development while keeping costs lower than larger production instance classes.

### Auto Scaling

The Auto Scaling Group is configured with:

* Minimum: 2
* Desired: 2
* Maximum: 4

This demonstrates production-style scaling behavior while limiting unnecessary resource usage.

### Private Networking

The project deploys two NAT Gateways to demonstrate a highly available, multi-Availability Zone architecture.

Although a single NAT Gateway would reduce cost, two NAT Gateways were chosen to reflect production best practices.

## Cleanup

Always verify that the following resources have been removed after running the destroy script:

* VPC
* NAT Gateways
* Elastic IP addresses
* Application Load Balancer
* Auto Scaling Group
* Launch Template
* EC2 instances
* Aurora Cluster
* Aurora Writer Instance
* Security Groups
* Route Tables
* Internet Gateway

Removing these resources helps prevent unexpected AWS charges.
