# https://hub.docker.com/_/rust
ARG BASE_IMAGE=rust:1.62.1-slim-bullseye

FROM $BASE_IMAGE as base
RUN cargo install cargo-chef --version 0.1.39

RUN apt-get update
RUN apt-get -y install curl unzip

ENV PB_REL="https://github.com/protocolbuffers/protobuf/releases/download/"
ENV PB_VER="v21.4"
# uncomment for Intel/AMD
# ENV PB_ZIP="protoc-21.4-linux-x86_64.zip"
# ARM64
ENV PB_ZIP="protoc-21.4-linux-aarch_64.zip"

RUN curl -LO ${PB_REL}${PB_VER}"/"${PB_ZIP}
RUN unzip ${PB_ZIP} -d protoc
RUN chmod +x protoc/bin/protoc
RUN cp protoc/bin/protoc /usr/bin
RUN cp -R protoc/include/* /usr/include

FROM base as builder
ADD . .
WORKDIR rusty-grpc/server
RUN cargo build --release

#FROM gcr.io/distroless/cc
FROM debian:bullseye-slim
COPY --from=builder /rusty-grpc/server/target/release/server /
EXPOSE 8080
CMD ["./server"]