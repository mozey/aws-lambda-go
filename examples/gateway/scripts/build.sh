#!/usr/bin/env bash

GOPATH=${GOPATH}
export AWS_DIR=${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway

echo "Building exe"
cd ${AWS_DIR}
env GOOS=linux GOARCH=amd64 go build \
-o build/gateway.out \
./cmd/gateway

zip -j ${AWS_DIR}/build/main.zip ${AWS_DIR}/build/gateway.out

unzip -vl ${AWS_DIR}/build/main.zip
