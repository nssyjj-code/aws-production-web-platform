#!/bin/bash

# scripts/lib/compute.sh
# Shared EC2 compute deployment helpers.

create_launch_template() {
  local launch_template_name="$1"
  local ami_id="$2"
  local instance_type="$3"
  local security_group_id="$4"
  local instance_profile_name="$5"
  local user_data_file="$6"

  aws ec2 create-launch-template \
    --region "$AWS_REGION" \
    --launch-template-name "$launch_template_name" \
    --version-description "Initial application server launch template" \
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
      \"UserData\": \"$(base64 -w 0 "$user_data_file")\",
      \"TagSpecifications\": [
        {
          \"ResourceType\": \"instance\",
          \"Tags\": [
            {\"Key\": \"Name\", \"Value\": \"$PROJECT_NAME-app-instance\"},
            {\"Key\": \"Project\", \"Value\": \"$PROJECT_NAME\"},
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

  if [[ "$launch_template_id" == "None" || -z "$launch_template_id" ]]; then
    log_info "Creating launch template: $launch_template_name" >&2
    launch_template_id=$(create_launch_template \
      "$launch_template_name" \
      "$ami_id" \
      "$instance_type" \
      "$security_group_id" \
      "$instance_profile_name" \
      "$user_data_file")
    log_success "Created launch template $launch_template_name: $launch_template_id" >&2
  else
    log_success "Launch template already exists: $launch_template_name ($launch_template_id)" >&2
  fi

  echo "$launch_template_id"
}