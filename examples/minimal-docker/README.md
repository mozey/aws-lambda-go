[Building Minimal Docker Containers for Go Applications](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker
    
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .
    
    docker build -t minimal-docker .
    
    docker run -it --rm minimal-docker
    
    