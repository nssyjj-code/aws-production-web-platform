# AWS Authentication

## Overview

This project provisions AWS infrastructure using the AWS CLI and authenticates through a dedicated IAM user configured locally on the developer workstation.

The authentication approach was intentionally selected for a personal development environment to simplify deployment and infrastructure testing.

For enterprise environments, AWS recommends short-lived credentials through IAM roles, IAM Identity Center (AWS SSO), or workload federation.

---

## Authentication Method Used

This project uses:

* AWS CLI v2
* IAM user credentials stored locally
* AWS shared credentials file
* AWS shared configuration file

Authentication is resolved through the AWS CLI credential provider chain.

The deployment scripts do not contain embedded credentials.

---

## Local Configuration

Configure credentials locally:

```bash
aws configure
```

Example configuration:

```text
AWS Access Key ID     = ********************
AWS Secret Access Key = ********************
Default region        = us-east-1
Output format         = json
```

Verify authentication:

```bash
aws sts get-caller-identity
```

Expected validation:

* Correct AWS account
* Correct IAM identity
* Correct AWS region

Infrastructure should only be deployed after identity verification is completed.

---

## Security Controls

The repository does not store AWS credentials.

Sensitive files remain local to the workstation:

```text
~/.aws/credentials
~/.aws/config
```

These files are excluded from source control.

Additional security measures:

* MFA enabled on the AWS account
* Least-privilege IAM permissions where practical
* Credentials never referenced directly in scripts
* Credentials resolved through AWS SDK and CLI authentication mechanisms

---

## Production Considerations

The authentication model used in this project is appropriate for a personal development environment but would not be the preferred approach for a production environment.

A production implementation would use one of the following:

### IAM Identity Center (AWS SSO)

Benefits:

* Centralized identity management
* Temporary credentials
* Improved auditing
* Simplified access revocation

### IAM Role Assumption

Benefits:

* No long-lived access keys
* Temporary credentials
* Reduced credential exposure risk

### CI/CD Federation

Example:

```text
GitHub Actions → OpenID Connect (OIDC) → AWS IAM Role
```

Benefits:

* No stored AWS secrets
* Short-lived credentials
* Automated deployment workflows

---

## Lessons Learned

This project reinforced several AWS security principles:

* Never store credentials in source control.
* Verify identity before provisioning resources.
* Prefer temporary credentials whenever possible.
* Separate development authentication practices from production authentication practices.
* Design automation to rely on AWS-native credential resolution rather than hardcoded secrets.