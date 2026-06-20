#!/bin/bash

# scripts/lib/security.sh
# Shared security group deployment helpers.

create_security_group() {
  local vpc_id="$1"
  local security_group_name="$2"
  local description="$3"
  local tier="$4"

  aws ec2 create-security-group \
    --region "$AWS_REGION" \
    --vpc-id "$vpc_id" \
    --group-name "$security_group_name" \
    --description "$description" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$security_group_name},{Key=Project,Value=$PROJECT_NAME},{Key=Tier,Value=$tier}]" \
    --query "GroupId" \
    --output text
}

ensure_security_group() {
  local vpc_id="$1"
  local security_group_name="$2"
  local description="$3"
  local tier="$4"
  local security_group_id

  security_group_id=$(find_security_group_by_name "$vpc_id" "$security_group_name")

  if [[ "$security_group_id" == "None" || -z "$security_group_id" ]]; then
    log_info "Creating security group: $security_group_name" >&2
    security_group_id=$(create_security_group "$vpc_id" "$security_group_name" "$description" "$tier")
    log_success "Created security group $security_group_name: $security_group_id" >&2
  else
    log_success "Security group already exists: $security_group_name ($security_group_id)" >&2
  fi

  echo "$security_group_id"
}

ensure_ingress_cidr_rule() {
  local security_group_id="$1"
  local protocol="$2"
  local from_port="$3"
  local to_port="$4"
  local cidr="$5"
  local description="$6"

  if aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --group-ids "$security_group_id" \
    --query "SecurityGroups[0].IpPermissions[?IpProtocol=='$protocol' && FromPort==\`$from_port\` && ToPort==\`$to_port\` && contains(IpRanges[].CidrIp, '$cidr')]" \
    --output text | grep -q "$cidr"; then

    log_success "Ingress rule already exists: $protocol $from_port-$to_port from $cidr"
  else
    log_info "Creating ingress rule: $protocol $from_port-$to_port from $cidr"

    aws ec2 authorize-security-group-ingress \
      --region "$AWS_REGION" \
      --group-id "$security_group_id" \
      --ip-permissions "IpProtocol=$protocol,FromPort=$from_port,ToPort=$to_port,IpRanges=[{CidrIp=$cidr,Description='$description'}]" \
      >/dev/null

    log_success "Created ingress rule: $protocol $from_port-$to_port from $cidr"
  fi
}

ensure_ingress_sg_rule() {
  local security_group_id="$1"
  local protocol="$2"
  local from_port="$3"
  local to_port="$4"
  local source_sg_id="$5"
  local description="$6"

  if aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --group-ids "$security_group_id" \
    --query "SecurityGroups[0].IpPermissions[?IpProtocol=='$protocol' && FromPort==\`$from_port\` && ToPort==\`$to_port\` && contains(UserIdGroupPairs[].GroupId, '$source_sg_id')]" \
    --output text | grep -q "$source_sg_id"; then

    log_success "Ingress rule already exists: $protocol $from_port-$to_port from $source_sg_id"
  else
    log_info "Creating ingress rule: $protocol $from_port-$to_port from $source_sg_id"

    aws ec2 authorize-security-group-ingress \
      --region "$AWS_REGION" \
      --group-id "$security_group_id" \
      --ip-permissions "IpProtocol=$protocol,FromPort=$from_port,ToPort=$to_port,UserIdGroupPairs=[{GroupId=$source_sg_id,Description='$description'}]" \
      >/dev/null

    log_success "Created ingress rule: $protocol $from_port-$to_port from $source_sg_id"
  fi
}