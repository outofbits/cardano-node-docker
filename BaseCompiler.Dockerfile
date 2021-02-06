FROM adalove/centos:8

ARG CABAL_VERSION
ARG GHC_VERSION

# install dependencies for cardano-node compilation
RUN dnf install -y gcc-c++ \
	gmp-devel \
	ncurses-compat-libs \
	ncurses-devel \
	zlib-devel \
	systemd-devel \
	&& dnf clean all

# install cabal
ADD https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz cabal-install.tar.xz
RUN tar -xf cabal-install.tar.xz && rm cabal-install.tar.xz cabal.sig
RUN mv cabal /usr/local/bin
RUN cabal update

# install ghc
ADD https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-centos7-linux.tar.xz ghc.tar.xz
RUN tar -xf ghc.tar.xz
RUN cd ghc-${GHC_VERSION} && ./configure && make install
RUN rm -rf ghc-${GHC_VERSION} ghc.tar.xz

# Documentation
LABEL maintainer="Kevin Haller <keivn.haller@outofbits.com>"
LABEL version="8-ghc${GHC_VERSION}-c${CABAL_VERSION}"
LABEL description="CentOS 8 Image ready to compile the Cardano Node."
