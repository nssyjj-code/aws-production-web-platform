#!/bin/bash

# scripts/lib/database.sh
# Shared RDS and Aurora database deployment helpers.

find_db_subnet_group_by_name() {
  local db_subnet_group_name="$1"

  aws rds describe-db-subnet-groups \
    --region "$AWS_REGION" \
    --db-subnet-group-name "$db_subnet_group_name" \
    --query "DBSubnetGroups[0].DBSubnetGroupName" \
    --output text 2>/dev/null || echo "None"
}

create_db_subnet_group() {
  local db_subnet_group_name="$1"
  local db_subnet_a_id="$2"
  local db_subnet_b_id="$3"

  aws rds create-db-subnet-group \
    --region "$AWS_REGION" \
    --db-subnet-group-name "$db_subnet_group_name" \
    --db-subnet-group-description "Private DB subnet group for $PROJECT_NAME" \
    --subnet-ids "$db_subnet_a_id" "$db_subnet_b_id" \
    --tags \
      "Key=Name,Value=$db_subnet_group_name" \
      "Key=Project,Value=$PROJECT_NAME" \
      "Key=Tier,Value=database" \
    --query "DBSubnetGroup.DBSubnetGroupName" \
    --output text
}

ensure_db_subnet_group() {
  local db_subnet_group_name="$1"
  local db_subnet_a_id="$2"
  local db_subnet_b_id="$3"
  local db_subnet_group

  db_subnet_group=$(find_db_subnet_group_by_name "$db_subnet_group_name")

  if [[ "$db_subnet_group" == "None" || -z "$db_subnet_group" ]]; then
    log_info "Creating DB subnet group: $db_subnet_group_name" >&2
    db_subnet_group=$(create_db_subnet_group "$db_subnet_group_name" "$db_subnet_a_id" "$db_subnet_b_id")
    log_success "Created DB subnet group: $db_subnet_group" >&2
  else
    log_success "DB subnet group already exists: $db_subnet_group" >&2
  fi

  echo "$db_subnet_group"
}

find_aurora_cluster_by_identifier() {
  local cluster_id="$1"

  aws rds describe-db-clusters \
    --region "$AWS_REGION" \
    --db-cluster-identifier "$cluster_id" \
    --query "DBClusters[0].DBClusterIdentifier" \
    --output text 2>/dev/null || echo "None"
}

create_aurora_cluster() {
  local cluster_id="$1"
  local subnet_group_name="$2"
  local db_sg_id="$3"

  aws rds create-db-cluster \
    --region "$AWS_REGION" \
    --db-cluster-identifier "$cluster_id" \
    --engine "$AURORA_ENGINE" \
    --database-name "$DB_NAME" \
    --master-username "$DB_MASTER_USERNAME" \
    --master-user-password "$DB_MASTER_PASSWORD" \
    --db-subnet-group-name "$subnet_group_name" \
    --vpc-security-group-ids "$db_sg_id" \
    --storage-encrypted \
    --backup-retention-period "$DB_BACKUP_RETENTION_DAYS" \
    --copy-tags-to-snapshot \
    --tags \
      "Key=Name,Value=$cluster_id" \
      "Key=Project,Value=$PROJECT_NAME" \
      "Key=Tier,Value=database" \
      "Key=Environment,Value=$ENVIRONMENT" \
    --query "DBCluster.DBClusterIdentifier" \
    --output text
}

ensure_aurora_cluster() {
  local cluster_id="$1"
  local subnet_group_name="$2"
  local db_sg_id="$3"
  local cluster

  cluster=$(find_aurora_cluster_by_identifier "$cluster_id")

  if [[ "$cluster" == "None" || -z "$cluster" ]]; then
    log_info "Creating Aurora cluster: $cluster_id" >&2

    if ! cluster=$(create_aurora_cluster "$cluster_id" "$subnet_group_name" "$db_sg_id"); then
      log_error "Failed to create Aurora cluster: $cluster_id" >&2
      exit 1
    fi

    log_success "Created Aurora cluster: $cluster" >&2
  else
    log_success "Aurora cluster already exists: $cluster" >&2
  fi

  echo "$cluster"
}

wait_for_aurora_cluster() {
  local cluster_id="$1"

  log_info "Waiting for Aurora cluster to become available: $cluster_id"

  aws rds wait db-cluster-available \
    --region "$AWS_REGION" \
    --db-cluster-identifier "$cluster_id"

  log_success "Aurora cluster is available: $cluster_id"
}

find_aurora_instance_by_identifier() {
  local instance_id="$1"

  aws rds describe-db-instances \
    --region "$AWS_REGION" \
    --db-instance-identifier "$instance_id" \
    --query "DBInstances[0].DBInstanceIdentifier" \
    --output text 2>/dev/null || echo "None"
}

create_aurora_instance() {
  local instance_id="$1"
  local cluster_id="$2"

  aws rds create-db-instance \
    --region "$AWS_REGION" \
    --db-instance-identifier "$instance_id" \
    --db-cluster-identifier "$cluster_id" \
    --engine "$AURORA_ENGINE" \
    --db-instance-class "$AURORA_INSTANCE_CLASS" \
    --no-publicly-accessible \
    --tags \
      "Key=Name,Value=$instance_id" \
      "Key=Project,Value=$PROJECT_NAME" \
      "Key=Tier,Value=database" \
      "Key=Environment,Value=$ENVIRONMENT" \
    --query "DBInstance.DBInstanceIdentifier" \
    --output text
}

ensure_aurora_instance() {
  local instance_id="$1"
  local cluster_id="$2"
  local instance

  instance=$(find_aurora_instance_by_identifier "$instance_id")

  if [[ "$instance" == "None" || -z "$instance" ]]; then
    log_info "Creating Aurora instance: $instance_id" >&2

    if ! instance=$(create_aurora_instance "$instance_id" "$cluster_id"); then
      log_error "Failed to create Aurora instance: $instance_id" >&2
      exit 1
    fi

    log_success "Created Aurora instance: $instance" >&2
  else
    log_success "Aurora instance already exists: $instance" >&2
  fi

  echo "$instance"
}

wait_for_aurora_instance() {
  local instance_id="$1"

  log_info "Waiting for Aurora instance to become available: $instance_id"

  aws rds wait db-instance-available \
    --region "$AWS_REGION" \
    --db-instance-identifier "$instance_id"

  log_success "Aurora instance is available: $instance_id"
}