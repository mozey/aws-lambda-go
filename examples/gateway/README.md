# [apex/gateway](https://github.com/apex/gateway)

provides a drop-in replacement for net/http's ListenAndServe 
for use in AWS Lambda & API Gateway, 
simply swap it out for gateway.ListenAndServe

Inspired by 
[aws-sam-golang-example](https://github.com/cpliakas/aws-sam-golang-example)

Example

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/gateway
    
    # net/http
    env APEX_GATEWAY_DISABLED=true go run main.go
    
    http localhost:3000
    http "localhost:3000/foo?foo=oof"
    
    # gateway
    GOOS=linux go build -o main && sam local start-api

Deploy to lambda

    # Package SAM template
    sam package --template-file ./template.yml --s3-bucket mozey --output-template-file packaged.yaml
    
    # Deploy packaged SAM template
    sam deploy --template-file ./packaged.yaml --stack-name mozey --capabilities CAPABILITY_IAM

APIGatewayProxyRequestContext contains the information to identify the 
AWS account and resources invoking the Lambda function. 
It also includes Cognito identity information for the caller. 
See [requestContext.Authorizer](https://github.com/apex/gateway/blame/cdfe71df1421609687c01dda11f13ef068784e5b/Readme.md#L31)
