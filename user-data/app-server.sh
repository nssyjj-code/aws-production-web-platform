#!/bin/bash

set -euo pipefail

dnf update -y
dnf install -y httpd

systemctl enable httpd
systemctl start httpd

cat > /var/www/html/index.html <<EOF
<html>
  <head>
    <title>AWS Production Web Platform</title>
  </head>
  <body>
    <h1>AWS Production Web Platform</h1>
    <p>Application server launched successfully.</p>
  </body>
</html>
EOF