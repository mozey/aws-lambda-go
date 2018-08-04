#!/usr/bin/env bash

# Set (e) exit on error
# Set (u) no-unset to exit on undefined variable
set -eu
# If any command in a pipeline fails,
# that return code will be used as the
# return code of the whole pipeline.
bash -c 'set -o pipefail'

EXPECTED_ARGS=2
E_BADARGS=100

if [ $# -ne ${EXPECTED_ARGS} ]
then
    echo "Delete lambda fn and API"
    echo ""
    echo "Usage:"
    echo "  ./script/`basename $0` APP_DIR APP_FN_NAME"
    echo ""
    exit ${E_BADARGS}
fi

APP_DIR="$1"
APP_FN_NAME="$2"

read -p "Delete lambda fn and API ${APP_FN_NAME} (y)? " -n 1 -r
echo ""
echo ""
if [[ ${REPLY} =~ ^[Yy]$ ]]
then
    # Other managed/inline policies to detach/delete?
    APP_POLICY_ARN=$(aws iam list-attached-role-policies \
    --role-name ${APP_FN_NAME} | \
    jq -r ".AttachedPolicies[]  | select(.PolicyName == \"AWSLambdaBasicExecutionRole\") | .PolicyArn") \
    || APP_POLICY_ARN=""
    if [ "${APP_POLICY_ARN}" != "" ]
    then
        echo "Detaching policy ${APP_POLICY_ARN}"
        aws iam detach-role-policy --role-name ${APP_FN_NAME} \
        --policy-arn ${APP_POLICY_ARN}
    fi

    DELETE_ROLE=1
    aws iam get-role --role-name ${APP_FN_NAME} > /dev/null || DELETE_ROLE=0
    if [ ${DELETE_ROLE} -eq 1 ]
    then
        echo "Deleting IAM role"
        aws iam delete-role --role-name ${APP_FN_NAME}
    fi

    DELETE_FN=1
    aws lambda get-function --function-name ${APP_FN_NAME} > /dev/null \
    || DELETE_FN=0
    if [ ${DELETE_FN} -eq 1 ]
    then
        echo "Deleting lambda fn"
        aws lambda delete-function --function-name ${APP_FN_NAME}
    fi

    APP_API_ID=$(aws apigateway get-rest-apis | \
    jq -r ".items[]  | select(.name == \"${APP_FN_NAME}\") | .id") \
    || APP_API_ID=""
    if [ "${APP_API_ID}" != "" ]
    then
        echo "Deleting API ${APP_API_ID}"
        aws apigateway delete-rest-api --rest-api-id ${APP_API_ID}
    fi

    echo "Reset config"
    cp ${APP_DIR}/config.sample.json ${APP_DIR}/config.json
    # TODO Unset APP_ env vars

    echo ""
    echo "Done"

else
    echo "Abort"
fi

