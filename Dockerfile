# Compiler Image (see BaseCompiler.Dockerfile for base image)
# --------------------------------------------------------------------------
FROM adalove/centos:8-ghc8.10.3-c3.2.0.0 AS compiler

ARG NODE_VERSION
ARG NODE_REPOSITORY
ARG NODE_BRANCH

# clone git repository
RUN git clone -b $NODE_BRANCH --recurse-submodules $NODE_REPOSITORY cardano-node
WORKDIR /cardano-node
RUN git fetch --all --tags
RUN git checkout tags/$NODE_VERSION --quiet

# compile cardano-node
RUN mkdir -p /binaries/
RUN cabal build all
RUN cp $(find /cardano-node -name cardano-cli -type f -executable) /binaries/
RUN cp $(find /cardano-node -name cardano-node -type f -executable) /binaries/

# Compiler for the health check program written in Go
# -------------------------------------------------------------------------
FROM golang:1.15 AS healthCheckCompiler

COPY healthcheck healthcheck
WORKDIR healthcheck

RUN mkdir -p /binaries/
RUN go mod vendor && go build
RUN mv healthcheck /binaries/

# Main Image (see Base.Dockerfile for base image)
# -------------------------------------------------------------------------
FROM adalove/centos:8

# Documentation
ENV DFILE_VERSION "1.6"

# add lovelace user
RUN useradd -m --uid 1402 lovelace

# Documentation
LABEL maintainer="Kevin Haller <keivn.haller@outofbits.com>"
LABEL version="${DFILE_VERSION}-node${NODE_VERSION}"
LABEL description="Blockchain node for Cardano (implemented in Haskell)."

COPY --from=compiler /binaries/cardano-node /usr/local/bin/
COPY --from=compiler /binaries/cardano-cli /usr/local/bin/
COPY --from=healthCheckCompiler /binaries/healthcheck /usr/local/bin/

USER lovelace

ENTRYPOINT ["cardano-node"]
