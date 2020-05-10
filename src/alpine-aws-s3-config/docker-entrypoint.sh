#!/usr/bin/dumb-init /bin/bash

set -e
set -o pipefail

# Define helper functions used in script and callbacks
ensure_env_var_set () {
    local name="$1"
    if [ -z "${!name}" ]; then
        echo >&2 "Error: missing ${name} environment variable."
        exit 1
    fi
}

fetch_value_from_metadata_service () {
    echo >&2 "Looking up instance metadata. [key: $1]"
    curl -s "http://169.254.169.254/latest/meta-data/$1"
}

source_callback () {
    local name="$1"
    if [ -n "${!name}" ]; then
        echo >&2 "Sourcing callback. [path: ${!name}]"
        source ${!name}
    fi
}

exec_callback () {
    local name="$1"
    shift
    echo >&2 "Exec'ing callback. [path: ${!name}]"
    exec ${!name} "$@"
}

build_env_file_from_s3 () {
    local region="$1"
    local object_path="$2"

    echo >&2 "Fetching and transforming env file from S3. [region: ${region}, object-path: ${object_path}]"
    aws s3 cp \
        --sse AES256 \
        --region ${region} \
        ${object_path} - | sed 's/^/export /'
}

fetch_file_from_s3 () {
    local region="$1"
    local object_path="$2"
    local local_path="$3"

    echo >&2 "Fetching file from S3. [region: ${region}, object-path: ${object_path}, local-path: ${local_path}]"
    mkdir -p $(dirname "$local_path")
    aws s3 cp --sse AES256 --region ${region} ${object_path} ${local_path}
}

add_env_var () {
    local name="$1"
    local value="$2"

    echo >&2 "Adding environment variable. [name: ${name}]"
    export ${name}=${value}
}

# Expose host details
SELF_ID=$(fetch_value_from_metadata_service "instance-id")
SELF_IP=$(fetch_value_from_metadata_service "local-ipv4")
SELF_HOSTNAME=$(fetch_value_from_metadata_service "local-hostname")

# Fetch and source env file from S3
ensure_env_var_set "S3_BUCKET_REGION"
ensure_env_var_set "ENV_FILE_S3_OBJECT_PATH"

eval \
    $(build_env_file_from_s3 \
        "${S3_BUCKET_REGION}" \
        "${ENV_FILE_S3_OBJECT_PATH}")

# Fetch secrets files
export -f fetch_file_from_s3
source_callback "FETCH_SECRETS_FILES_SCRIPT_PATH"
unset -f fetch_file_from_s3

# Export additional environment
export -f add_env_var
source_callback "EXPORT_ADDITIONAL_ENVIRONMENT_SCRIPT_PATH"
unset -f add_env_var

# Delegate to startup script
exec_callback "STARTUP_SCRIPT_PATH" "$@"
