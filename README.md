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


# [Cloudformation Custom Domain](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-domainname.html)

[Custom Domains](https://github.com/awslabs/serverless-application-model/issues/248)
not yet supported with SAM


# [AWS lambda in action](https://www.manning.com/books/aws-lambda-in-action)

[Live Demos](https://eventdrivenapps.com/#livedemos)

[Dynamic Serverless Website](https://github.com/danilop/AWS_Lambda_in_Action/tree/master/Chapter07/SimpleWebsite)
built using Amazon API Gateway, AWS Lambda and EJS templates.

[Sample Authentication](https://github.com/danilop/AWS_Lambda_in_Action/tree/master/Chapter09/SampleAuth)
service built with AWS Lambda, Amazon DynamoDB, Amazon SES, and integrated with 
Amazon Cognito as Developer Authenticated Identities


# Code layout

[GitHubCodeLayout](https://github.com/golang/go/wiki/GitHubCodeLayout)

[golang-standards/project-layout](https://github.com/golang-standards/project-layout)


# Local AWS for dev

Instructions to setup AWS services locally with usage examples
[aws-local](https://github.com/mozey/aws-local)

    




