#!/usr/bin/env bash

EXPECTED_ARGS=2
E_BADARGS=100

if [ $# -ne ${EXPECTED_ARGS} ]
then
    echo "Deploy updates to the lambda fn"
    echo ""
    echo "Usage:"
    echo "  ./script/`basename $0` APP_DIR APP_FN_NAME"
    echo ""
    exit ${E_BADARGS}
fi

APP_DIR="$1"
APP_FN_NAME="$2"

echo "Deploying lambda fn ${APP_FN_NAME}..."
aws lambda update-function-code --function-name ${APP_FN_NAME} \
--zip-file fileb://${APP_DIR}/build/main.zip

