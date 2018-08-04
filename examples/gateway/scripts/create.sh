#!/usr/bin/env bash

# Set (e) exit on error
# Set (u) no-unset to exit on undefined variable
set -eu
# If any command in a pipeline fails,
# that return code will be used as the
# return code of the whole pipeline.
bash -c 'set -o pipefail'

E_BADARGS=100

APP_DIR=${APP_DIR}
if [ "${APP_DIR}" = "" ]
then
    echo "Invalid APP_DIR"
    exit ${E_BADARGS}
fi
APP_FN_NAME=${APP_FN_NAME}
if [ "${APP_FN_NAME}" = "" ]
then
    echo "Invalid APP_FN_NAME"
    exit ${E_BADARGS}
fi
APP_HANDLER=${APP_HANDLER}
if [ "${APP_HANDLER}" = "" ]
then
    echo "Invalid APP_HANDLER"
    exit ${E_BADARGS}
fi

# Lambda fn.....................................................................

echo "Creating lambda fn..."
echo ""

aws iam create-role --role-name ${APP_FN_NAME} \
--assume-role-policy-document file://${APP_DIR}/trust-policy.json

APP_POLICY=AWSLambdaBasicExecutionRole

AWS_POLICY_ARN=arn:aws:iam::aws:policy/service-role/${APP_POLICY}

aws iam attach-role-policy --role-name ${APP_FN_NAME} \
--policy-arn ${AWS_POLICY_ARN}

APP_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

APP_ROLE_ARN="arn:aws:iam::${APP_ACCOUNT}:role/${APP_FN_NAME}"

aws lambda create-function --function-name ${APP_FN_NAME} --runtime go1.x \
--role ${APP_ROLE_ARN} \
--handler ${APP_HANDLER} --zip-file fileb://${APP_DIR}/build/main.zip


# API...........................................................................

echo "Creating API deployment..."
echo ""

APP_API_NAME=${APP_FN_NAME}

APP_API_ID=$(aws apigateway create-rest-api \
--name ${APP_FN_NAME} | jq -r .id)

# Get APP_API_ID by name
#APP_API_ID=$(aws apigateway get-rest-apis | \
#jq -r ".items[]  | select(.name == \"${APP_FN_NAME}\") | .id")

APP_API_ROOT_ID=$(aws apigateway get-resources \
--rest-api-id ${APP_API_ID} | jq -r .items[0].id)

APP_API_RESOURCE_ID=$(aws apigateway create-resource \
--rest-api-id ${APP_API_ID} \
--parent-id ${APP_API_ROOT_ID} \
--path-part "{proxy+}" | jq -r .id)

aws apigateway put-method --rest-api-id ${APP_API_ID} \
--resource-id ${APP_API_RESOURCE_ID} --http-method ANY \
--authorization-type NONE

APP_FN_ARN=$(aws lambda get-function \
--function-name ${APP_FN_NAME} | jq -r .Configuration.FunctionArn)

APP_REGION=eu-west-2

aws apigateway put-integration --rest-api-id ${APP_API_ID} \
--resource-id ${APP_API_RESOURCE_ID} --http-method ANY --type AWS_PROXY \
--integration-http-method POST \
--uri arn:aws:apigateway:${APP_REGION}:lambda:path/2015-03-31/functions/${APP_FN_ARN}/invocations

APP_STATEMENT_ID=$(uuidgen)

aws lambda add-permission --function-name ${APP_FN_NAME} \
--statement-id ${APP_STATEMENT_ID} \
--action lambda:InvokeFunction --principal apigateway.amazonaws.com \
--source-arn arn:aws:execute-api:${APP_REGION}:${APP_ACCOUNT}:${APP_API_ID}/*/*/*

# Add multi stage logic here...
APP_STAGE_NAME=main

aws apigateway create-deployment --rest-api-id ${APP_API_ID} \
--stage-name ${APP_STAGE_NAME}

APP_ENDPOINT="https://${APP_API_ID}.execute-api.${APP_REGION}.amazonaws.com/${APP_STAGE_NAME}"

# Update config...................................................................

echo "Update config"
echo ""

${APP_DIR}/config \
-key "APP_POLICY" -value "${APP_POLICY}" \
-key "AWS_POLICY_ARN" -value "${AWS_POLICY_ARN}" \
-key "APP_ACCOUNT" -value "${APP_ACCOUNT}" \
-key "APP_ROLE_ARN" -value "${APP_ROLE_ARN}" \
-key "APP_API_ID" -value "${APP_API_ID}" \
-key "APP_API_ROOT_ID" -value "${APP_API_ROOT_ID}" \
-key "APP_ENDPOINT" -value "${APP_ENDPOINT}" \
-key "APP_API_RESOURCE_ID" -value "${APP_API_RESOURCE_ID}" \
-key "APP_FN_ARN" -value "${APP_FN_ARN}" \
-key "APP_REGION" -value "${APP_REGION}" \
-key "APP_STATEMENT_ID" -value "${APP_STATEMENT_ID}" \
-key "APP_STAGE_NAME" -value "${APP_STAGE_NAME}" \
-update

echo "Done"

