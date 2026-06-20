# AWS Authentication

## Overview

This project uses short-lived AWS credentials through AWS IAM Identity Center (AWS SSO) instead of long-lived IAM user access keys.
Using temporary credentials for production environments helps:

* Eliminate long-lived access keys from developer machines.
* Reduce the risk of credential compromise.
* Support centralized access management.
* Align with AWS security best practices.

## Configure an AWS SSO Profile

Run the following command to configure a new AWS SSO profile:

```sh
aws configure sso --profile portfolio-admin
```

Follow the prompts to configure:

* AWS SSO Start URL
* AWS SSO Region
* AWS Account
* Permission Set (Role)
* Default Region
* Output Format

## Authenticate

Start an authenticated session:

```sh
aws sso login --profile portfolio-admin
```

The AWS CLI will open a browser window to complete authentication.

## Verify Authentication

Confirm the active AWS account before deploying infrastructure:

```sh
aws sts get-caller-identity --profile portfolio-admin
```

Verify the returned Account ID matches the intended AWS account.

## Deploy Infrastructure

Run deployment scripts using the configured profile:

```sh
AWS_PROFILE=portfolio-admin <script>
```

## Security Notes

* Never commit AWS credentials to source control.
* Prefer temporary credentials over long-lived IAM access keys.
* Verify the active AWS account before running deployment scripts.
* Sign in again with `aws sso login` if the session expires.
