# Dockerfile.distroless
ARG BASE_IMAGE=rust:1.62.1-slim-buster
FROM $BASE_IMAGE as builder

RUN apt-get update
RUN apt-get -y install protobuf-compiler
RUN protoc --version

ADD . .

WORKDIR rusty-grpc/server

RUN cargo build --release

# Prod stage
FROM gcr.io/distroless/cc
COPY --from=builder /rusty-grpc/server/target/release/server /
CMD ["./server"]