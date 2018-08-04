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
APP_ENDPOINT_CUSTOM=${APP_ENDPOINT_CUSTOM}
if [ "${APP_ENDPOINT_CUSTOM}" = "" ]
then
    echo "Invalid APP_ENDPOINT_CUSTOM"
    exit ${E_BADARGS}
fi
APP_DOMAIN=${APP_DOMAIN}
if [ "${APP_DOMAIN}" = "" ]
then
    echo "Invalid APP_DOMAIN"
    exit ${E_BADARGS}
fi
APP_REGION=${APP_REGION}
if [ "${APP_REGION}" = "" ]
then
    echo "Invalid APP_REGION"
    exit ${E_BADARGS}
fi
APP_API_ID=${APP_API_ID}
if [ "${APP_API_ID}" = "" ]
then
    echo "Invalid APP_API_ID"
    exit ${E_BADARGS}
fi
APP_STAGE_NAME=${APP_STAGE_NAME}
if [ "${APP_STAGE_NAME}" = "" ]
then
    echo "Invalid APP_STAGE_NAME"
    exit ${E_BADARGS}
fi

# ..............................................................................
APP_CERT_ARN=$(aws acm list-certificates | \
jq -r ".CertificateSummaryList[] | select(.DomainName == \"${APP_ENDPOINT_CUSTOM}\") | .CertificateArn")
if [ "${APP_CERT_ARN}" = "" ]
then
    echo "Requesting cert for ${APP_ENDPOINT_CUSTOM}"
    echo ""
    aws acm request-certificate \
    --region ${APP_REGION} \
    --domain-name ${APP_ENDPOINT_CUSTOM} --validation-method DNS
    APP_CERT_ARN=$(aws acm list-certificates | \
    jq -r ".CertificateSummaryList[] | select(.DomainName == \"${APP_ENDPOINT_CUSTOM}\") | .CertificateArn")
fi

# ..............................................................................

APP_DNS_VALIDATION=$(aws acm describe-certificate \
--certificate-arn ${APP_CERT_ARN} | \
jq -r .Certificate.DomainValidationOptions[0].ResourceRecord)
APP_VALIDATION_CNAME=$(echo ${APP_DNS_VALIDATION} | jq -r .Name)
APP_VALIDATION_VALUE=$(echo ${APP_DNS_VALIDATION} | jq -r .Value)
APP_HOSTED_ZONE=$(aws route53 list-hosted-zones | \
jq -r ".HostedZones[] | select(.Name == \"${APP_DOMAIN}.\") | .Id")
if [ "${APP_HOSTED_ZONE}" = "" ]
then
    echo "Invalid APP_HOSTED_ZONE"
    exit ${E_BADARGS}
fi

CREATE_CNAME=$(aws route53 list-resource-record-sets --hosted-zone-id ${APP_HOSTED_ZONE} | \
jq -r ".ResourceRecordSets[] | select(.Name == \"${APP_VALIDATION_CNAME}\") | .Name")
if [ "${CREATE_CNAME}" = "" ]
then
    echo "Creating CNAME record for DSN validation"
    echo ""
    echo "
    {
        \"Comment\": \"DNS validation for custom domain\",
        \"Changes\": [
            {
                \"Action\": \"CREATE\",
                \"ResourceRecordSet\": {
                    \"Name\": \"${APP_VALIDATION_CNAME}\",
                    \"Type\": \"CNAME\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [
                        {
                            \"Value\": \"${APP_VALIDATION_VALUE}\"
                        }
                    ]
                }
            }
        ]
    }
    " > ${APP_DIR}/change-resource-record-sets.json
    aws route53 change-resource-record-sets --hosted-zone-id ${APP_HOSTED_ZONE} \
    --change-batch file://${APP_DIR}/change-resource-record-sets.json
fi

# ..............................................................................
echo "Check cert status"
echo ""
APP_CERT_STATUS=$(aws acm describe-certificate \
--certificate-arn ${APP_CERT_ARN} | \
jq -r .Certificate.Status)
# TODO What is the correct verified status?
if [ "${APP_CERT_STATUS}" != "VERIFIED" ]
then
    echo "Invalid APP_CERT_STATUS ${APP_CERT_STATUS}"
    exit ${E_BADARGS}
fi

# ..............................................................................
echo "Create API domain"
echo ""
aws apigateway create-domain-name \
--domain-name ${APP_ENDPOINT_CUSTOM} \
--certificate-name ${APP_ENDPOINT_CUSTOM} \
--region ${APP_REGION} \
--certificate-arn ${APP_CERT_ARN}

# ..............................................................................
echo "Create API path mapping"
echo ""
aws apigateway create-base-path-mapping \
--domain-name ${APP_ENDPOINT_CUSTOM} \
--rest-api-id ${APP_API_ID} \
--stage ${APP_STAGE_NAME} \
--region ${APP_REGION}

# ..............................................................................
echo "Update config"
echo ""
${APP_DIR}/config \
-key "APP_CERT_ARN" -value "${APP_CERT_ARN}" \
-update
