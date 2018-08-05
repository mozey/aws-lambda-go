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
APP_FN_HANDLER=${APP_FN_HANDLER}
if [ "${APP_FN_HANDLER}" = "" ]
then
    echo "Invalid APP_FN_HANDLER"
    exit ${E_BADARGS}
fi
AWS_PROFILE=${AWS_PROFILE}
if [ "${AWS_PROFILE}" = "" ]
then
    echo "Invalid AWS_PROFILE"
    exit ${E_BADARGS}
fi

# Lambda fn.....................................................................

echo "Creating lambda fn..."
echo ""

aws iam create-role --role-name ${APP_FN_NAME} \
--assume-role-policy-document file://${APP_DIR}/trust-policy.json

POLICY=AWSLambdaBasicExecutionRole
APP_FN_POLICY_ARN=arn:aws:iam::aws:policy/service-role/${POLICY}

aws iam attach-role-policy --role-name ${APP_FN_NAME} \
--policy-arn ${APP_FN_POLICY_ARN}

APP_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)

APP_FN_ROLE_ARN="arn:aws:iam::${APP_ACCOUNT}:role/${APP_FN_NAME}"

aws lambda create-function --function-name ${APP_FN_NAME} --runtime go1.x \
--role ${APP_FN_ROLE_ARN} \
--handler ${APP_FN_HANDLER} --zip-file fileb://${APP_DIR}/build/main.zip


# API...........................................................................

echo "Creating API deployment..."
echo ""

APP_API_NAME=${APP_FN_NAME}

APP_API=$(aws apigateway create-rest-api \
--name ${APP_FN_NAME} | jq -r .id)

# Get APP_API by name
#APP_API=$(aws apigateway get-rest-apis | \
#jq -r ".items[]  | select(.name == \"${APP_FN_NAME}\") | .id")

APP_API_ROOT=$(aws apigateway get-resources \
--rest-api-id ${APP_API} | jq -r .items[0].id)

APP_API_RESOURCE=$(aws apigateway create-resource \
--rest-api-id ${APP_API} \
--parent-id ${APP_API_ROOT} \
--path-part "{proxy+}" | jq -r .id)

aws apigateway put-method --rest-api-id ${APP_API} \
--resource-id ${APP_API_RESOURCE} --http-method ANY \
--authorization-type NONE

APP_FN_ARN=$(aws lambda get-function \
--function-name ${APP_FN_NAME} | jq -r .Configuration.FunctionArn)

APP_REGION=eu-west-2

aws apigateway put-integration --rest-api-id ${APP_API} \
--resource-id ${APP_API_RESOURCE} --http-method ANY --type AWS_PROXY \
--integration-http-method POST \
--uri arn:aws:apigateway:${APP_REGION}:lambda:path/2015-03-31/functions/${APP_FN_ARN}/invocations

APP_FN_PERM=$(uuidgen)

aws lambda add-permission --function-name ${APP_FN_NAME} \
--statement-id ${APP_FN_PERM} \
--action lambda:InvokeFunction --principal apigateway.amazonaws.com \
--source-arn arn:aws:execute-api:${APP_REGION}:${APP_ACCOUNT}:${APP_API}/*/*/*

# Add multi stage logic here...
APP_API_STAGE_NAME=main

aws apigateway create-deployment --rest-api-id ${APP_API} \
--stage-name ${APP_API_STAGE_NAME}

APP_API_ENDPOINT="https://${APP_API}.execute-api.${APP_REGION}.amazonaws.com/${APP_API_STAGE_NAME}"

# Update config...................................................................

${APP_DIR}/config \
-key "APP_FN_POLICY_ARN" -value "${APP_FN_POLICY_ARN}" \
-key "APP_ACCOUNT" -value "${APP_ACCOUNT}" \
-key "APP_FN_ROLE_ARN" -value "${APP_FN_ROLE_ARN}" \
-key "APP_API" -value "${APP_API}" \
-key "APP_API_ROOT" -value "${APP_API_ROOT}" \
-key "APP_API_ENDPOINT" -value "${APP_API_ENDPOINT}" \
-key "APP_API_RESOURCE" -value "${APP_API_RESOURCE}" \
-key "APP_FN_ARN" -value "${APP_FN_ARN}" \
-key "APP_REGION" -value "${APP_REGION}" \
-key "APP_FN_PERM" -value "${APP_FN_PERM}" \
-key "APP_API_STAGE_NAME" -value "${APP_API_STAGE_NAME}" \
-key "AWS_PROFILE" -value "${AWS_PROFILE}" \
-update

echo "Done"

