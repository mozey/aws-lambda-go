[Building Minimal Docker Containers for Go Applications](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)

Curl google.com

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker
    
    # Copy ca-certificates.crt from system to ./curl
    
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./curl/main.out ./curl
    
    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/curl/Dockerfile \
    -t md-curl --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/curl
    
    docker run -it --rm --name md-curl md-curl
    
Serve http on localhost

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker

    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./http/main.out ./http
    
    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/http/Dockerfile \
    -t md-http --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/http
    
    docker run -d -it --rm -p 8080:80 --name md-http md-http
    
    http localhost:8080/pho
    
Serve https on localhost,
uses [vfsgen](https://github.com/shurcooL/vfsgen)

    cd $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker

    # https://letsencrypt.org/docs/certificates-for-localhost/    
    openssl req -x509 -out ./https/localhost.crt -keyout ./https/localhost.key \
    -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=localhost' -extensions EXT -config <( \
    printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    # Debug
    go run https/main.go -certs $(pwd)/https -dataDir $(pwd)/https/data &
    http --verify no https://localhost:8080/mien
    http --verify no https://localhost:8080/data/foo.html
    
    go build -o ./https/main.out ./https
    ./https/main.out -certs $(pwd)/https -dataDir $(pwd)/https/data

    # Linux executable
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o ./https/main.out ./https

    docker build \
    -f $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/https/Dockerfile \
    -t md-https --rm \
    $GOPATH/src/github.com/mozey/aws-lambda-go/examples/minimal-docker/https
    
    docker stop md-https
    docker run -d -it --rm -p 8080:8080 --name md-https md-https
    
    http --verify no https://localhost:8080/mienchon
    http --verify no https://localhost:8080/data/foo.html

Expose local servers to internet securely,
host [tunnel](https://github.com/labstack/tunnel) in docker

     