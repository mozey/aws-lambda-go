#!/usr/bin/env bash

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

echo "Deploying lambda fn ${APP_FN_NAME}..."
aws lambda update-function-code --function-name ${APP_FN_NAME} \
--zip-file fileb://${APP_DIR}/build/main.zip

