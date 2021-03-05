#!/bin/bash

# This script creates a channel and a group pointing to a package with the given
# PACKAGE_VERSION.

set -eu

set -o pipefail

NEBRASKA_URL="${NEBRASKA_URL:-http://nebraska:8000}"
PACKAGE_VERSION="${PACKAGE_VERSION:?Must set PACKAGE_VERSION}"
CHANNEL_NAME="${CHANNEL_NAME:?Must set CHANNEL_NAME}"
GROUP_NAME="${CHANNEL_NAME:?Must set GROUP_NAME}"
UPDATES_ENABLED="${UPDATES_ENABLED:-true}"

function update() {
  # find Flatcar application
  echo "INFO - finding Flatcar application"
  local application_id
  application_id=$(curl -sSf "${NEBRASKA_URL}/api/apps" | jq -r '.[] | select(.name == "Flatcar Container Linux") | .id')
  if [[ -z "${application_id}" ]]; then
    echo "ERROR - can't find Flatcar Container Linux application"
    exit 1
  fi
  echo "INFO - found application ${application_id}"

  # find requested package
  echo "INFO - finding package with version ${PACKAGE_VERSION}"
  local package_id
  package_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/packages" \
    | jq -r ".[] | select(.version == \"${PACKAGE_VERSION}\") | .id"
  )
  if [[ -z "${package_id}" ]]; then
    echo "ERROR - can't find package with version ${PACKAGE_VERSION}"
    exit 1
  fi
  echo "INFO - found package ${package_id}"

  # the channel we want to create/update
  local channel_payload
  channel_payload=$(cat <<EOF
{
  "name": "${CHANNEL_NAME}",
  "package_id": "${package_id}",
  "arch": 1
}
EOF
  )
  # find requested channel
  echo "INFO - finding channel with name ${CHANNEL_NAME}"
  local channel_id
  channel_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/channels" \
    | jq -r ".[] | select(.name == \"${CHANNEL_NAME}\") | select(.arch == 1) | .id"
  )
  if [[ -z "${channel_id}" ]]; then
    # if channel doesn't exist, create it
    echo "INFO - channel ${CHANNEL_NAME} doesn't exist, creating it"
    channel_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/channels" \
      -XPOST \
      -d "${channel_payload}" \
      | jq -r '.id'
    )
    echo "INFO - created channel ${channel_id}"
  else
    # otherwise, update it
    echo "INFO - updating channel ${channel_id}"
    channel_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/channels/${channel_id}" \
      -XPUT \
      -d "${channel_payload}" \
      | jq -r '.id'
    )
    echo "INFO - updated channel ${channel_id}"
  fi

  # the group we want to create/update
  local group_payload
  group_payload=$(cat <<EOF
{
  "channel_id": "${channel_id}",
  "name": "${GROUP_NAME}",
  "track": "${GROUP_NAME}",
  "policy_max_updates_per_period": 999999,
  "policy_period_interval": "1 minutes",
  "policy_update_timeout": "60 minutes",
  "policy_updates_enabled":${UPDATES_ENABLED}
}
EOF
  )

  # find requested group
  echo "INFO - finding group with track ${GROUP_NAME}"
  local group_id
  group_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/groups" \
    | jq -r ".[] | select(.track == \"${GROUP_NAME}\") | select(.channel.arch == 1) | .id"
  )
  if [[ -z "${group_id}" ]]; then
    # if group doesn't exist, create it
    echo "INFO - group ${GROUP_NAME} doesn't exist, creating it"
    group_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/groups" \
      -XPOST \
      -d "${group_payload}" \
      | jq -r '.id'
    )
    echo "INFO - created group ${group_id}"
  else
    # otherwise, update it
    echo "INFO - updating group ${group_id}"
    group_id=$(curl -sSf "${NEBRASKA_URL}/api/apps/${application_id}/groups/${group_id}" \
      -XPUT \
      -d "${group_payload}" \
      | jq -r '.id'
    )
    echo "INFO - updated group ${group_id}"
  fi
}

while true; do
  update
  echo "INFO - sleeping for 1h"
  sleep 3600
done
