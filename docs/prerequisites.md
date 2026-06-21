# Prerequisites

Before deploying this platform, ensure the following tools, permissions, and environment variables are in place.

---

## Required Tools

| Tool | Minimum Version | Installation |
|---|---|---|
| AWS CLI | v2.x | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Bash | 4.0+ | Pre-installed on macOS/Linux. Windows users: use Git Bash or WSL2 |
| Git | 2.x | [git-scm.com](https://git-scm.com/) |

### Verify your installations

```bash
aws --version        # Expected: aws-cli/2.x.x
bash --version       # Expected: GNU bash, version 4.x or 5.x
git --version        # Expected: git version 2.x.x
```

---

## AWS Account Requirements

This project provisions the following AWS resources. Your account must have sufficient service limits and IAM permissions to create them.

### Services used

- **VPC** — 1 VPC (`10.0.0.0/16`), 6 subnets across 2 Availability Zones (2 public, 2 private app, 2 private DB)
- **EC2** — Auto Scaling Group with a desired capacity of 2 instances (min: 2, max: 4)
- **Elastic Load Balancing** — 1 Application Load Balancer across public subnets
- **NAT Gateway** — 2 NAT Gateways, one per Availability Zone
- **Aurora MySQL** — 1 Aurora cluster deployed across private database subnets
- **IAM** — Roles and instance profiles for EC2 access

### Estimated cost

> ⚠️ Leaving this infrastructure running will incur AWS charges. Estimated cost is approximately **$80–$120/month** at default capacity (2 EC2 instances + 2 NAT Gateways + Aurora cluster in `us-east-1`). Run the teardown script when not in use.

---

## IAM Permissions

The AWS identity used to run the deploy scripts must have permissions to create and manage the services listed above.

The minimum required actions span the following IAM service namespaces:

- `ec2:*` (VPC, subnets, security groups, instances, NAT gateways, internet gateway, route tables)
- `elasticloadbalancing:*` (ALB, target groups, listeners)
- `autoscaling:*` (Auto Scaling Groups, launch templates)
- `rds:*` (Aurora cluster, subnet groups, parameter groups)
- `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PassRole`, `iam:CreateInstanceProfile`

> If you are using an IAM user for testing, attaching the `AdministratorAccess` managed policy is the fastest way to get started. For a production environment, scope permissions to the minimum required actions above.

### Configure AWS CLI credentials

```bash
aws configure
```

You will be prompted for:

```
AWS Access Key ID:      <your-access-key-id>
AWS Secret Access Key:  <your-secret-access-key>
Default region name:    us-east-1
Default output format:  json
```

Verify the correct identity is active before deploying:

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
  "UserId": "AIDA...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

---

## Environment Variables

The deploy scripts read the following environment variables at runtime. Export them in your shell before running any script.

```bash
# AWS region to deploy into
export AWS_REGION="us-east-1"

# Name prefix applied to all provisioned resources
export PROJECT_NAME="aws-prod-platform"

# EC2 key pair name for SSH access to instances (must already exist in your AWS account)
export KEY_PAIR_NAME="your-key-pair-name"

# Aurora database credentials
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"   # Min 8 characters, no special shell characters
```

> **Security note:** Do not commit these values to source control. Use a `.env` file (already listed in `.gitignore`) or a secrets manager such as AWS Secrets Manager for any shared or production deployment.

### Verify your environment

```bash
echo "Region:  $AWS_REGION"
echo "Project: $PROJECT_NAME"
echo "Key:     $KEY_PAIR_NAME"
```

---

## Networking Requirements

- Outbound internet access is required from your local machine to reach AWS API endpoints.
- The deploy scripts do not require inbound ports to be open on your machine.
- EC2 instances are deployed in **private subnets** and are not directly reachable from the internet. Outbound traffic from instances routes through NAT Gateways.

---

## Region Availability

This project is configured for **`us-east-1` (N. Virginia)** and uses two Availability Zones: `us-east-1a` and `us-east-1b`.

To deploy to a different region, update `AWS_REGION` and verify that Aurora MySQL and Application Load Balancer are available in your target region:

```bash
aws ec2 describe-availability-zones --region <your-region> --query 'AvailabilityZones[].ZoneName'
```

---

## Next Steps

Once all prerequisites are met, proceed to the [deployment guide](./deployment.md) to provision the infrastructure.