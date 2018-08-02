#!/usr/bin/env bash

GOPATH=${GOPATH}
export AWS_DIR=${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway

export AWS_FN_NAME="aws-lambda-go-examples-gateway"

echo "Updating lambda fn..."
aws lambda update-function-code --function-name ${AWS_FN_NAME} \
--zip-file fileb://${AWS_DIR}/build/main.zip

