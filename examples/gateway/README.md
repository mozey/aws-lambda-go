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

    cd ${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway
    
    # net/http
    go run ./cmd/http/http.go &
    http localhost:8080
    http "localhost:8080/foo?foo=foo"
    
    
# Create lambda fn and API

    cd ${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway
 
Make scripts executable
 
    chmod u+x ./scripts/*.sh
 
Set env using `config` cmd.
The `config.json` file must be in the package root, 
it is used to derive `APP_DIR`

    # Init
    export AWS_PROFILE=mozey
    export APP_DEBUG=true
    export APP_CONFIG=$(pwd)/config.json
    cp ./config.sample.json ./config.json
    
    # Compile config cmd
    go build -ldflags "-X main.Config=$APP_CONFIG" -o ./config ./scripts/config
    
    # Set env
    $(./config)
    
Print env

    printenv | sort | grep -E 'AWS_|APP_'
    
Build the exe

    ./scripts/build.sh ${APP_DIR} ${APP_HANDLER}

Create lambda fn and API

    ./scripts/create.sh ${APP_DIR} ${APP_FN_NAME} ${APP_HANDLER}
    $(./config) 
    
Test

    http ${APP_ENDPOINT}/foo?foo=foo


# Deploy to update the lambda fn
    
    ./scripts/deploy.sh ${APP_DIR} ${APP_FN_NAME}

    
# Delete lambda fn and API

    ./scripts/reset.sh ${APP_DIR} ${APP_FN_NAME}


# Custom domain
    
Add custom domain that invokes the API,
all request methods and paths are forwarded to the lambda fn
    
    export APP_ENDPOINT_CUSTOM=api.example.com
    
    ./scripts/domain.sh ${APP_ENDPOINT_CUSTOM}
    # Update config
    ./config -key APP_ENDPOINT_CUSTOM -value ${APP_ENDPOINT_CUSTOM}


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


