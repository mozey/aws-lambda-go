[Building Minimal Docker Containers for Go Applications](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)

Curl google.com

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker
    
    # Copy ca-certificates.crt from system to ./curl
    
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./curl/main.out ./curl
    
    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/curl/Dockerfile \
    -t minimal-docker-curl --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/curl
    
    docker run -it --rm --name minimal-docker-curl minimal-docker-curl
    
Serve http on localhost

    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./http/main.out ./http
    
    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/http/Dockerfile \
    -t minimal-docker-http --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/http
    
    docker run -d -it --rm -p 8080:80 --name minimal-docker-http minimal-docker-http
    
    http localhost:8080/pho
    
TODO Serve https on localhost

    # https://letsencrypt.org/docs/certificates-for-localhost/    
    openssl req -x509 -out ./https/localhost.crt -keyout ./https/localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=localhost' -extensions EXT -config <( \
    printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    # Debug
    go build -o ./https/main.out ./https
    ./https/main.out

    # Linux executable
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./https/main.out ./https

    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/https/Dockerfile \
    -t minimal-docker-https --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/https
    
    docker stop minimal-docker-http
    docker run -d -it --rm -p 8080:8080 --name minimal-docker-https minimal-docker-https
    
    http https://localhost:8080/mien