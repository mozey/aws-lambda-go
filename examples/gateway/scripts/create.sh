#!/usr/bin/env bash

# Set (e) exit on error
# Set (u) no-unset to exit on undefined variable
set -eu
# If any command in a pipeline fails,
# that return code will be used as the
# return code of the whole pipeline.
bash -c 'set -o pipefail'

GOPATH=${GOPATH}
export AWS_DIR=${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway

# Lambda fn

export AWS_FN_NAME="aws-lambda-go-examples-gateway"
export AWS_ROLE=${AWS_FN_NAME}

aws iam create-role --role-name ${AWS_ROLE} \
--assume-role-policy-document file://${AWS_DIR}/trust-policy.json

export AWS_POLICY=AWSLambdaBasicExecutionRole

aws iam attach-role-policy --role-name ${AWS_ROLE} \
--policy-arn arn:aws:iam::aws:policy/service-role/${AWS_POLICY}

export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
export AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT}:role/${AWS_ROLE}"

aws lambda create-function --function-name ${AWS_FN_NAME} --runtime go1.x \
--role ${AWS_ROLE_ARN} \
--handler gateway.out --zip-file fileb://${AWS_DIR}/build/main.zip


# API

export AWS_API_NAME=${AWS_FN_NAME}

aws apigateway create-rest-api --name ${AWS_API_NAME}

export AWS_API_ID=$(aws apigateway get-rest-apis | \
jq -r ".items[]  | select(.name == \"${AWS_API_NAME}\") | .id")

export AWS_API_ROOT_ID=$(aws apigateway get-resources \
--rest-api-id ${AWS_API_ID} | jq -r .items[0].id)

export AWS_API_RESOURCE_ID=$(aws apigateway create-resource \
--rest-api-id ${AWS_API_ID} \
--parent-id ${AWS_API_ROOT_ID} \
--path-part "{proxy+}" | jq -r .id)

aws apigateway put-method --rest-api-id ${AWS_API_ID} \
--resource-id ${AWS_API_RESOURCE_ID} --http-method ANY \
--authorization-type NONE

export AWS_FN_ARN=$(aws lambda get-function \
--function-name ${AWS_FN_NAME} | jq -r .Configuration.FunctionArn)

export AWS_REGION=eu-west-2

aws apigateway put-integration --rest-api-id ${AWS_API_ID} \
--resource-id ${AWS_API_RESOURCE_ID} --http-method ANY --type AWS_PROXY \
--integration-http-method POST \
--uri arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${AWS_FN_ARN}/invocations

export AWS_STATEMENT_ID=$(uuidgen)

aws lambda add-permission --function-name ${AWS_FN_NAME} \
--statement-id ${AWS_STATEMENT_ID} \
--action lambda:InvokeFunction --principal apigateway.amazonaws.com \
--source-arn arn:aws:execute-api:${AWS_REGION}:${AWS_ACCOUNT}:${AWS_API_ID}/*/*/*

export AWS_STAGE_NAME=dev

aws apigateway create-deployment --rest-api-id ${AWS_API_ID} \
--stage-name ${AWS_STAGE_NAME}

export AWS_ENDPOINT=https://${AWS_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${AWS_STAGE_NAME}

echo ${AWS_ENDPOINT} > ${AWS_DIR}/endpoint.txt