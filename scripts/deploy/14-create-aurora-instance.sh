#!/bin/bash

# 14-create-aurora-instance.sh
# Creates the Aurora MySQL writer instance.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../config/environment.conf"
source "$SCRIPT_DIR/../lib/validation.sh"
source "$SCRIPT_DIR/../lib/database.sh"

main() {
  validate_prerequisites

  log_info "Retrieving Aurora cluster..."
  CLUSTER_ID=$(find_aurora_cluster_by_identifier "$AURORA_CLUSTER_IDENTIFIER")
  require_id "Aurora Cluster" "$AURORA_CLUSTER_IDENTIFIER" "$CLUSTER_ID"

  log_info "Ensuring Aurora writer instance exists..."
  INSTANCE_ID=$(ensure_aurora_instance "$AURORA_WRITER_INSTANCE_IDENTIFIER" "$CLUSTER_ID")
  require_id "Aurora Instance" "$AURORA_WRITER_INSTANCE_IDENTIFIER" "$INSTANCE_ID"

  wait_for_aurora_instance "$INSTANCE_ID"

  log_success "Aurora writer instance configured successfully: $INSTANCE_ID"
}

main "$@"