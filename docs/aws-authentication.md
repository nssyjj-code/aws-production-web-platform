# AWS Authentication

## Overview

This repository uses the AWS CLI to provision infrastructure within a personal AWS account.

For this project, authentication is performed using an IAM user with programmatic access configured through the AWS CLI. While this approach is appropriate for a personal development environment, enterprise environments should use short-lived credentials through AWS IAM Identity Center (AWS SSO) or assumed IAM roles.

## Prerequisites

Before deploying infrastructure, ensure you have:

* An AWS account
* An IAM user with programmatic access
* AWS CLI v2 installed
* Permissions to create and manage the resources used by this project

## Configure the AWS CLI

Configure your AWS credentials:

```sh
aws configure
```

Provide the following information when prompted:

```text
AWS Access Key ID
AWS Secret Access Key
Default region: us-east-1
Default output format: json
```

## Verify Authentication

Before running any deployment scripts, verify that the AWS CLI is authenticated against the intended AWS account.

```sh
aws sts get-caller-identity
```

Review the returned output and confirm:

* The expected AWS Account ID
* The correct IAM user or role
* The intended AWS account before creating infrastructure

## Security Considerations

This repository intentionally avoids embedding credentials within deployment scripts.
AWS credentials are resolved through the AWS CLI credential provider chain.
Never commit the following files to source control:

```text
~/.aws/credentials
~/.aws/config
```

These files should remain local to each developer's workstation.

## Future Improvements

For a production enterprise environment, authentication would typically be implemented using:

* AWS IAM Identity Center (AWS SSO)
* IAM role assumption
* Temporary credentials
* CI/CD federation (for example, GitHub Actions using OpenID Connect)

These approaches eliminate long-lived access keys and provide centralized identity and access management.
