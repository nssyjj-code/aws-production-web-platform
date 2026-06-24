#!/bin/bash

set -euo pipefail

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "===== User Data Execution Started ====="
date

dnf update -y

dnf install -y httpd curl jq

systemctl enable httpd
systemctl start httpd

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")
HOSTNAME=$(hostname)

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>AWS Production Web Platform</title>
</head>
<body>
    <h1>AWS Production Web Platform</h1>

    <p>Application server launched successfully.</p>

    <h2>Instance Information</h2>

    <ul>
        <li><strong>Hostname:</strong> ${HOSTNAME}</li>
        <li><strong>Instance ID:</strong> ${INSTANCE_ID}</li>
        <li><strong>Availability Zone:</strong> ${AZ}</li>
    </ul>
</body>
</html>
EOF

cat > /var/www/html/health.html <<EOF
OK
EOF

systemctl restart httpd

echo "===== User Data Execution Complete ====="
date