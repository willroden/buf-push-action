# Code generated by ezactions. DO NOT EDIT.

FROM golang:1.20.0-alpine AS builder
RUN apk --no-cache add ca-certificates git

WORKDIR	/src
COPY . .
RUN go build \
    -o /bin/buf-push-action \
    -ldflags "-s -w -extldflags '-static'" \
    ./cmd/buf-push-action

FROM alpine:3.11
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /bin/buf-push-action /buf-push-action

ENTRYPOINT ["/buf-push-action"]
