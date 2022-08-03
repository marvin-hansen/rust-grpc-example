# Dockerfile.distroless
# https://github.com/azzamsa/rust-docker
# https://azzamsa.com/n/rust-docker/

# https://hub.docker.com/_/rust
ARG BASE_IMAGE=rust:1.62.1-slim-bullseye

FROM $BASE_IMAGE as base
RUN cargo install cargo-chef --version 0.1.39

RUN apt-get update
RUN apt-get -y install curl unzip

ENV PB_REL="https://github.com/protocolbuffers/protobuf/releases/download/"
ENV PB_VER="v21.4"
# for Intel/AMD use protoc-21.4-linux-x86_64.zip
ENV PB_ZIP="protoc-21.4-linux-aarch_64.zip"

RUN curl -LO ${PB_REL}${PB_VER}"/"${PB_ZIP}
RUN unzip ${PB_ZIP} -d protoc
RUN chmod +x protoc/bin/protoc
RUN cp protoc/bin/protoc /usr/bin
RUN cp -R protoc/include/* /usr/include

FROM base as planner
ADD . .
WORKDIR rusty-grpc/server
RUN cargo chef prepare  --recipe-path recipe.json

FROM base as cacher
WORKDIR rusty-grpc/server
COPY --from=planner /rusty-grpc/server/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM base as builder
ADD . .
WORKDIR rusty-grpc/server
COPY --from=cacher /rusty-grpc/server/target target
COPY --from=cacher $CARGO_HOME $CARGO_HOME
RUN cargo build --release

FROM gcr.io/distroless/cc
COPY --from=builder /rusty-grpc/server/target/release/server /
EXPOSE 8080
CMD ["./server"]