#build golang http server
FROM oraclelinux:7-slim as builder
RUN yum install -y oracle-golang-release-el7 \ 
   && yum install -y git golang \
   && yum clean all

RUN mkdir -p /go
ENV GOPATH=/go

WORKDIR /go
RUN mkdir -p ./src/webhook
COPY src/* ./src/webhook
RUN go build ./src/webhook

#Final image
FROM oraclelinux:7-slim 
COPY  --from=builder /go/webhook /bin/webhook


ENTRYPOINT ["/bin/webhook"]
