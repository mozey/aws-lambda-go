#!/usr/bin/env bash

# Set (e) exit on error
# Set (u) no-unset to exit on undefined variable
set -eu
# If any command in a pipeline fails,
# that return code will be used as the
# return code of the whole pipeline.
bash -c 'set -o pipefail'

# Delete lambda fn
AWS_FN_NAME=${AWS_FN_NAME}
# TODO

# Delete API
AWS_API_NAME=${AWS_API_NAME}
AWS_API_ID=$(aws apigateway get-rest-apis | \
jq -r ".items[]  | select(.name == \"${AWS_API_NAME}\") | .id")
echo "Deleting rest-api-id ${AWS_API_ID}"
aws apigateway delete-rest-api --rest-api-id ${AWS_API_ID}
