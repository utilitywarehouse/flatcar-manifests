#!/bin/bash

set -e
set -u
set -o pipefail

## Required env vars 
DESIRED_VERSION="${DESIRED_VERSION:?"Must set DESIRED_VERSION"}"
# Should be set in the container spec
NODE_NAME="${NODE_NAME:?"Must set NODE_NAME"}"
# These should be set in the pod by Kubernetes
KUBERNETES_SERVICE_HOST="${KUBERNETES_SERVICE_HOST:?"Must set KUBERNETES_SERVICE_HOST"}" 
KUBERNETES_SERVICE_PORT="${KUBERNETES_SERVICE_PORT?"Must set KUBERNETES_SERVICE_PORT"}"

## Optional env vars 
ANNOTATION_NAME="${ANNOTATION_NAME:-"flatcar-linux-update.v1.flatcar-linux.net/before-reboot-version-ctl-ok"}"

valid_version() {
  local version=$1
  if [[ "${version}" =~ ^[0-9]{4}\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  fi

  return 1
}

get_new_version() {
  local new_version
  new_version=$(update_engine_client -status 2>/dev/null | grep ^NEW_VERSION | sed 's/^NEW_VERSION=//g')

  if ! valid_version "${new_version}"; then
    echo "Error: unexpected value for NEW_VERSION: ${new_version}" >&2
    exit 1
  fi

  echo "${new_version}"
}

new_version=$(get_new_version)

if [[ "${DESIRED_VERSION}" != "current" ]]; then
  # With the exception of 'current', DESIRED_VERSION should be a valid release
  # version
  if ! valid_version "${DESIRED_VERSION}"; then
    echo "Error: unexpected value for DESIRED_VERSION: ${DESIRED_VERSION}" >&2
    exit 1
  fi

  # If the new version is an earlier version than the desired one then reset the
  # status and check for a newer update. Wait until the update-engine reports the
  # UPDATE_STATUS_UPDATED_NEED_REBOOT status again.
  if [[ "${new_version}" != "${DESIRED_VERSION}" ]] &&\
     [[ "$(printf "%s\n%s" "${new_version}" "${DESIRED_VERSION}" | sort -rV | head -1)" == "${DESIRED_VERSION}" ]]; then
    echo "Updating to the latest version because the new version (${new_version}) is less than the desired version (${DESIRED_VERSION})" >&2
    update_engine_client -reset-status
    update_engine_client -check_for_update
    while ! update_engine_client -status 2>/dev/null | grep -q "^CURRENT_OP=UPDATE_STATUS_UPDATED_NEED_REBOOT$"; do
      sleep 3
    done
    new_version=$(get_new_version)
    echo "Finished updating version. New version is: ${new_version}" >&2
  fi
fi

if [[ "${new_version}" == "${DESIRED_VERSION}" ]] || [[ "${DESIRED_VERSION}" == "current" ]]; then
  echo "Patching node with annotation: ${ANNOTATION_NAME}=true" >&2
  curl -sSf --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    -H "Content-Type: application/strategic-merge-patch+json" \
    -X PATCH \
    -d "{\"metadata\":{\"annotations\":{\"${ANNOTATION_NAME}\":\"true\"}}}" \
    "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/${NODE_NAME}?fieldManager=kubectl-annotate"
else
  echo "New version (${new_version}) doesn't match the desired version (${DESIRED_VERSION}). Sleeping indefinitely..." >&2
fi

while true; do sleep 86400; done
