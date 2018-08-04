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
APP_HANDLER=${APP_HANDLER}
if [ "${APP_HANDLER}" = "" ]
then
    echo "Invalid APP_HANDLER"
    exit ${E_BADARGS}
fi

echo "Building exe"
cd ${APP_DIR}
env GOOS=linux GOARCH=amd64 go build \
-o build/${APP_HANDLER} \
./cmd/gateway

echo "Delete old build"
# Release could be set to git tag...
RELEASE=""
NAME="main${RELEASE}.zip"
rm -f ${APP_DIR}/build/${NAME}

echo "Zip new build"
zip -j ${APP_DIR}/build/${NAME} ${APP_DIR}/build/${APP_HANDLER}
# Add more build artifacts here...

echo "List zip contents"
unzip -vl ${APP_DIR}/build/${NAME}
