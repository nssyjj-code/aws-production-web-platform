#!/bin/bash

# scripts/lib/compute.sh
# Shared EC2 compute deployment helpers.

encode_user_data() {
  local user_data_file="$1"

  if [[ ! -f "$user_data_file" ]]; then
    log_error "User data file not found: $user_data_file"
    exit 1
  fi

  base64 "$user_data_file" | tr -d '\n'
}

create_launch_template() {
  local launch_template_name="$1"
  local ami_id="$2"
  local instance_type="$3"
  local security_group_id="$4"
  local instance_profile_name="$5"
  local user_data_file="$6"
  local encoded_user_data

  encoded_user_data="$(encode_user_data "$user_data_file")"

  aws_cli ec2 create-launch-template \
    --launch-template-name "$launch_template_name" \
    --version-description "Application server launch template for $PROJECT_NAME" \
    --launch-template-data "{
      \"ImageId\": \"$ami_id\",
      \"InstanceType\": \"$instance_type\",
      \"IamInstanceProfile\": {
        \"Name\": \"$instance_profile_name\"
      },
      \"SecurityGroupIds\": [
        \"$security_group_id\"
      ],
      \"MetadataOptions\": {
        \"HttpTokens\": \"required\",
        \"HttpEndpoint\": \"enabled\"
      },
      \"Monitoring\": {
        \"Enabled\": true
      },
      \"UserData\": \"$encoded_user_data\",
      \"TagSpecifications\": [
        {
          \"ResourceType\": \"instance\",
          \"Tags\": [
            {\"Key\": \"Name\", \"Value\": \"$PROJECT_NAME-app-instance\"},
            {\"Key\": \"Project\", \"Value\": \"$PROJECT_NAME\"},
            {\"Key\": \"Environment\", \"Value\": \"${ENVIRONMENT:-development}\"},
            {\"Key\": \"ManagedBy\", \"Value\": \"aws-cli\"},
            {\"Key\": \"Tier\", \"Value\": \"app\"}
          ]
        },
        {
          \"ResourceType\": \"volume\",
          \"Tags\": [
            {\"Key\": \"Name\", \"Value\": \"$PROJECT_NAME-app-volume\"},
            {\"Key\": \"Project\", \"Value\": \"$PROJECT_NAME\"},
            {\"Key\": \"Environment\", \"Value\": \"${ENVIRONMENT:-development}\"},
            {\"Key\": \"ManagedBy\", \"Value\": \"aws-cli\"},
            {\"Key\": \"Tier\", \"Value\": \"app\"}
          ]
        }
      ]
    }" \
    --query "LaunchTemplate.LaunchTemplateId" \
    --output text
}

ensure_launch_template() {
  local launch_template_name="$1"
  local ami_id="$2"
  local instance_type="$3"
  local security_group_id="$4"
  local instance_profile_name="$5"
  local user_data_file="$6"
  local launch_template_id

  launch_template_id=$(find_launch_template_by_name "$launch_template_name")

  if ! exists "$launch_template_id"; then
    log_info "Creating launch template: $launch_template_name"
    launch_template_id=$(create_launch_template \
      "$launch_template_name" \
      "$ami_id" \
      "$instance_type" \
      "$security_group_id" \
      "$instance_profile_name" \
      "$user_data_file")
    log_success "Created launch template $launch_template_name: $launch_template_id"
  else
    log_success "Launch template already exists: $launch_template_name ($launch_template_id)"
  fi

  echo "$launch_template_id"
}