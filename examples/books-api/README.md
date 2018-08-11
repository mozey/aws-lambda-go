[Serverless API with Go and AWS Lambda](https://www.alexedwards.net/blog/serverless-api-with-go-and-aws-lambda)

...an API with two actions
    
    GET     /books?isbn=xxx     Display book info by ISBN
    
    POST    /books	            Create a new book
    
    
Build the exe. 
Zip must not contain dir path

    cd ${GOPATH}/src/github.com/mozey/aws-lambda-go/examples/books-api

    env GOOS=linux GOARCH=amd64 go build -o main.out ./books
    
    zip -j main.zip main.out && unzip -vl main.zip
    
    
Set up a role which defines the permission that 
the lambda fn will have when it is running.
The trust policy instructs AWS to allow 
lambda services to assume the specified role

    export AWS_FN_NAME="aws-lambda-go-examples-books-api"
    export AWS_ROLE=${AWS_FN_NAME}
    aws iam create-role --role-name ${AWS_ROLE} \
    --assume-role-policy-document file://trust-policy.json
    
    export AWS_ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
    export AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT}:role/${AWS_ROLE}"
    
    
Attach policy to the role to give it basic permission to run and log,
see [Lambda Permissions Model](https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html)

    export AWS_POLICY=AWSLambdaBasicExecutionRole
    aws iam attach-role-policy --role-name ${AWS_ROLE} \
    --policy-arn arn:aws:iam::aws:policy/service-role/${AWS_POLICY}


Create and deploy lambda fn

    aws lambda create-function --function-name ${AWS_FN_NAME} --runtime go1.x \
    --role ${AWS_ROLE_ARN} \
    --handler main.out --zip-file fileb://main.zip
    
    
Invoke the fn
    
    aws lambda invoke --function-name ${AWS_FN_NAME} output.json && \
    cat output.json
    
    export AWS_ISBN=978-1420931693
    aws lambda invoke --function-name ${AWS_FN_NAME} \
    --payload "{\"queryStringParameters\": {\"isbn\": \"${AWS_ISBN}\"}}" \
    output.json && \
    cat output.json
    
    aws lambda list-functions
    
    
Deploy updates

    aws lambda update-function-code --function-name ${AWS_FN_NAME} \
    --zip-file fileb://main.zip
    
    
TODO Hooking it up to DynamoDB

Monolithic project structure is easier to manage and test,
but be aware of the 50MB zip file size 
[deployment limit](https://docs.aws.amazon.com/lambda/latest/dg/limits.html)
    
    
Create API,
match all request methods and paths 

    export AWS_API_NAME=${AWS_FN_NAME}
    export AWS_API_ID=$(aws apigateway create-rest-api \
    --name ${AWS_FN_NAME} | jq -r .id)
    
    export AWS_API_ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id ${AWS_API_ID} | jq -r .items[0].id)
    
    export AWS_API_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id ${AWS_API_ID} \
    --parent-id ${AWS_API_ROOT_ID} \
    --path-part {proxy+} | jq -r .id)

    aws apigateway put-method --rest-api-id ${AWS_API_ID} \
    --resource-id ${AWS_API_RESOURCE_ID} --http-method ANY \
    --authorization-type NONE
    
Integrate resource with lambda fn.
The AWS_PROXY type makes gateway forward the http request to lambda,
and automatically transform the fn output to a http response.
The integration method is not related to the http request method.

    export AWS_FN_ARN=$(aws lambda get-function \
    --function-name ${AWS_FN_NAME} | jq -r .Configuration.FunctionArn)
    
    export AWS_REGION=eu-west-2
    aws apigateway put-integration --rest-api-id ${AWS_API_ID} \
    --resource-id ${AWS_API_RESOURCE_ID} --http-method ANY --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${AWS_FN_ARN}/invocations

Give API permission to execute lambda fn

    export AWS_STATEMENT_ID=$(uuidgen)
    
    aws lambda add-permission --function-name ${AWS_FN_NAME} \
    --statement-id ${AWS_STATEMENT_ID} \
    --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
    --source-arn arn:aws:execute-api:${AWS_REGION}:${AWS_ACCOUNT}:${AWS_API_ID}/*/*/*
    
Invoke via API

    aws apigateway test-invoke-method --rest-api-id ${AWS_API_ID} \
    --resource-id ${AWS_API_RESOURCE_ID} --http-method "GET" \
    --path-with-query-string "/books?isbn=${AWS_ISBN}"
    
View cloudwatch logs

    aws logs filter-log-events --log-group-name /aws/lambda/${AWS_FN_NAME}

    aws logs filter-log-events --log-group-name /aws/lambda/${AWS_FN_NAME} \
    --filter-pattern "ERROR"
    
Deploying the API

    export AWS_STAGE_NAME=$(uuidgen)

    aws apigateway create-deployment --rest-api-id ${AWS_API_ID} \
    --stage-name ${AWS_STAGE_NAME}
    
Set env given fn name 
and invoke lambda fn

    export AWS_PROFILE=YOUR_PROFILE_HERE
    export AWS_FN_NAME="aws-lambda-go-examples-books-api"
    
    export AWS_API_ID=$(aws apigateway get-rest-apis | \
    jq -r ".items[]  | select(.name == \"${AWS_FN_NAME}\") | .id")
    export AWS_REGION=eu-west-2
    export AWS_STAGE_NAME=$(aws apigateway get-stages \
    --rest-api-id ${AWS_API_ID} | \
    jq -r ".item[0].stageName")

    export AWS_ENDPOINT=https://${AWS_API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${AWS_STAGE_NAME}
    
    http ${AWS_ENDPOINT}/books?isbn=${AWS_ISBN}
    
Reset to delete lambda fn and API created above

    ./reset.sh
    
TODO Supporting multiple actions