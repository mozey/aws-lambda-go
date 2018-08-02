# [apex/gateway](https://github.com/apex/gateway)

provides a drop-in replacement for net/http's ListenAndServe 
for use in AWS Lambda & API Gateway, 
simply swap it out for gateway.ListenAndServe

Layout follows [go project layout](https://medium.com/golang-learn/go-project-layout-e5213cdcfaa2)
and [github here](https://github.com/golang-standards/project-layout)

Inspired by 
[aws-sam-golang-example](https://github.com/cpliakas/aws-sam-golang-example)


# Example

    cd ${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/gateway
    
    # net/http
    go run ./cmd/http/http.go &
    http localhost:8080
    http "localhost:8080/foo?foo=foo"
    
    
# Deploy to lambda
 
See [books-api](https://github.com/mozey/aws-lambda-go/tree/master/examples/books-api)

    chmod u+x ./scripts/*.sh

Build the exe

    ./scripts/build.sh

Create lambda fn and API.

    ./scripts/create.sh
    
Test

    export AWS_ENDPOINT=$(cat ./endpoint.txt)
    http ${AWS_ENDPOINT}/foo?foo=foo
    
Deploy to update the lambda fn
    
    ./scripts/deploy.sh
    
Delete lambda fn and API

    ./scripts/reset.sh
    
Add custom domain that invokes prod API,
proxies all request methods and paths to the lambda fn.
DNS records for the domain must be edited manually
    
    ./scripts/domain.sh api.example.com
    
Env variables

    printenv | sort | grep AWS_


# Caller id

APIGatewayProxyRequestContext contains the information to identify the 
AWS account and resources invoking the Lambda function. 
It also includes Cognito identity information for the caller. 
See [requestContext.Authorizer](https://github.com/apex/gateway/blame/cdfe71df1421609687c01dda11f13ef068784e5b/Readme.md#L31)


# sam local (untested)

    GOOS=linux go build -o main ./cmd/gateway && sam local start-api -p 8080
    # Credentials store error?

    # Package SAM template
    sam package --template-file ./template.yml --s3-bucket mozey \
    --output-template-file packaged.yaml
    
    # Deploy packaged SAM template
    sam deploy --template-file ./packaged.yaml --stack-name mozey \
    --capabilities CAPABILITY_IAM


