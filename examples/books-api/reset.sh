#!/usr/bin/env bash

# Set (e) exit on error
# Set (u) no-unset to exit on undefined variable
set -eu
# If any command in a pipeline fails,
# that return code will be used as the
# return code of the whole pipeline.
bash -c 'set -o pipefail'

export AWS_FN_NAME="aws-lambda-go-examples-books-api"

read -p "Reset ${AWS_FN_NAME} (y)? " -n 1 -r
echo    # move to a new line
if [[ ${REPLY} =~ ^[Yy]$ ]]
then
    # Delete lambda fn
    echo "Deleting lambda fn"
    aws lambda delete-function --function-name ${AWS_FN_NAME}

    # Delete API
    export AWS_API_NAME=${AWS_API_NAME}
    export AWS_API_ID=$(aws apigateway get-rest-apis | \
    jq -r ".items[]  | select(.name == \"${AWS_API_NAME}\") | .id")
    echo "Deleting rest-api-id ${AWS_API_ID}"
    aws apigateway delete-rest-api --rest-api-id ${AWS_API_ID}

    echo "Done"

else
    echo "Abort"
fi

