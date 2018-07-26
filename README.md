# [aws-lambda-go](https://github.com/aws/aws-lambda-go)

Notes about working with AWS Lambda functions written in Golang


# [Programming model](https://docs.aws.amazon.com/lambda/latest/dg/go-programming-model.html)

[Logging](https://docs.aws.amazon.com/lambda/latest/dg/go-programming-model-logging.html)

Lambda writes logs to CloudWatch.
By importing the log module, 
Lambda will write additional logging information such as the time stamp.

[Lambda Function Handler](https://docs.aws.amazon.com/lambda/latest/dg/go-programming-model-handler-types.html#go-programming-model-handler-execution-environment-reuse)

You can declare and modify global variables 
that are independent of your Lambda function's handler code.


# [Running Go AWS Lambda functions locally](https://djhworld.github.io/post/2018/01/27/running-go-aws-lambda-functions-locally/)

Using `lambda.Start` enables performance benefits,
AWS isn’t simply just running your go binary every time a function is invoked,
dependencies load up front so they are warm if your fn is called repeatedly


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


# [Cloudformation Custom Domain](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-domainname.html)

[Custom Domains](https://github.com/awslabs/serverless-application-model/issues/248)
not yet supported with SAM


# [Live Demos](https://eventdrivenapps.com/#livedemos)

[AWS lambda in action](https://www.manning.com/books/aws-lambda-in-action)

Dynamic Serverless Website, 
[Authentication](https://github.com/danilop/AWS_Lambda_in_Action/tree/master/Chapter09/SampleAuth)


# Code layout

[GitHubCodeLayout](https://github.com/golang/go/wiki/GitHubCodeLayout)

[golang-standards/project-layout](https://github.com/golang-standards/project-layout)


# Local AWS for dev

Instructions to setup AWS services locally with usage examples
[aws-local](https://github.com/mozey/aws-local)

    




