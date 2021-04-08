ARG GHC_VERSION=8.10.3
ARG CABAL_VERSION=3.4

# Compiler Image
# --------------------------------------------------------------------------
FROM adalove/ubuntu:20.04-ghc${GHC_VERSION}-c${CABAL_VERSION} AS compiler

ARG NODE_BRANCH
ARG NODE_VERSION

WORKDIR /
RUN git clone "https://github.com/input-output-hk/cardano-node.git" cardano-node -b $NODE_BRANCH --recurse-submodules && \
    cd cardano-node && \
    git fetch --all --tags && \
    git checkout tags/$NODE_VERSION --quiet
RUN cd cardano-node && \ 
    cabal update && \
    cabal build all && \
    mkdir -p /binaries/ && \
    cp $(find /cardano-node -name cardano-cli -type f -executable) /binaries/ && \
    cp $(find /cardano-node -name cardano-node -type f -executable) /binaries/

# Compiler for the health check program written in Go
# -------------------------------------------------------------------------
FROM golang:1.15 AS healthCheckCompiler

COPY healthcheck healthcheck
WORKDIR healthcheck
RUN mkdir -p /binaries/ && \
    go mod vendor && go build && \
    mv healthcheck /binaries/

# Main Image
# -------------------------------------------------------------------------
FROM adalove/ubuntu:20.04

ENV DFILE_VERSION "1.7"

# add lovelace user
RUN groupadd -r lovelace --gid 1402 && \
    useradd --no-log-init --uid 1402 -r -g lovelace lovelace

USER lovelace

# Documentation
LABEL maintainer="Kevin Haller <keivn.haller@outofbits.com>"
LABEL version="${DFILE_VERSION}-node${NODE_VERSION}"
LABEL description="Blockchain node for Cardano (implemented in Haskell)."

COPY --from=compiler /binaries/cardano-node /usr/local/bin/
COPY --from=compiler /binaries/cardano-cli /usr/local/bin/
COPY --from=healthCheckCompiler /binaries/healthcheck /usr/local/bin/

ENTRYPOINT ["cardano-node"]
