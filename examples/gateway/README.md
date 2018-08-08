# [apex/gateway](https://github.com/apex/gateway)

...provides a drop-in replacement for net/http's ListenAndServe 
for use in AWS Lambda & API Gateway, 
simply swap it out for gateway.ListenAndServe

Layout follows [go project layout](https://medium.com/golang-learn/go-project-layout-e5213cdcfaa2)
and [github here](https://github.com/golang-standards/project-layout)

Use of gateway inspired by [aws-sam-golang-example](https://github.com/cpliakas/aws-sam-golang-example),
but this example does not use sam local

Use monolithic lambda fn (routing is done internal to the fn) by default, 
see [Serverless API with Go and AWS Lambda](https://github.com/mozey/aws-lambda-go/tree/master/examples/books-api).
Pass in an optional path prefix when creating the fn

Use a [shared library](https://stackoverflow.com/a/35060357/639133) 
if the lambda zip [size limit](https://docs.aws.amazon.com/lambda/latest/dg/limits.html)
becomes an issue: "Each Lambda function receives an additional 512MB of 
non-persistent disk space in its own /tmp directory..."


# Run locally for dev

    export APP_DIR=${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway
    
    # net/http
    go run ${APP_DIR}/cmd/dev/dev.go &
    http localhost:8080
    http "localhost:8080/foo?foo=foo"
    
    
# Create lambda fn and API

Set application working dir

    export APP_DIR=${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway
 
Make scripts executable
 
    chmod u+x ${APP_DIR}/scripts/*.sh
 
Set env using `config` cmd.
The `config.json` file must be in the package root, 
for multiple environments use this format `config.APP_CONFIG_ENV.json`.
[AWS_PROFILE](https://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
should be set in `config.json`

    cp ${APP_DIR}/config.sample.json ${APP_DIR}/config.json
    
    cd ${APP_DIR}
    go build -ldflags "-X main.AppDir=${APP_DIR}" -o ./config ./cmd/config
    
    ${APP_DIR}/config \
    -key APP_REGION -value eu-west-2 \
    -update
    
    $(${APP_DIR}/config)
    
Print env

    printenv | sort | grep -E 'AWS_|APP_'
    
Build the exe

    $(${APP_DIR}/config) && ${APP_DIR}/scripts/build.sh
    
Deploy to update the lambda fn
    
    $(${APP_DIR}/config) && ${APP_DIR}/scripts/deploy.sh

Create lambda fn and API

    $(${APP_DIR}/config) && ${APP_DIR}/scripts/create.sh
    
Call API

    $(${APP_DIR}/config)
    
    http ${APP_API_ENDPOINT}/foo?foo=foo


# Delete lambda fn and API

    $(${APP_DIR}/config) && ${APP_DIR}/scripts/reset.sh


# Custom domain
    
Add a custom domain to invoke the lambda fn via API gateway,
all request methods and paths are forwarded to the lambda fn
    
    ${APP_DIR}/config \
    -key APP_API_PATH -value "" \
    -key APP_API_CUSTOM -value api.mozey.co \
    -key APP_API_DOMAIN -value mozey.co \
    -update
    
    $(${APP_DIR}/config) && ${APP_DIR}/scripts/domain.sh
    
Script will print an error message if cert is still validating.
Wait for certificate validation to complete,
then run the script again to finish setup
    
Call API (DNS may take some time to propagate)

    $(${APP_DIR}/config)
    
    http ${APP_API_CUSTOM_ENDPOINT}/foo?foo=foo


# Caller id

APIGatewayProxyRequestContext contains the information to identify the 
AWS account and resources invoking the Lambda function. 
It also includes Cognito identity information for the caller. 
See [requestContext.Authorizer](https://github.com/apex/gateway/blame/cdfe71df1421609687c01dda11f13ef068784e5b/Readme.md#L31)


# sam local

Alternative to deploy lambda functions and test them locally

Commands below are untested...

    GOOS=linux go build -o main ./cmd/gateway 
    
    # TODO Credentials store error?
    sam local start-api -p 8080

    # Package SAM template
    sam package --template-file ./template.yml --s3-bucket ${APP_BUCKET} \
    --output-template-file packaged.yaml
    
    # Deploy packaged SAM template
    sam deploy --template-file ./packaged.yaml --stack-name ${APP_STACK_NAME} \
    --capabilities CAPABILITY_IAM


