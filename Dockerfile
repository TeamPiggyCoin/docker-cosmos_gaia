#BUILDS TeamPiggyCoin/cosmos_gaia
#MAINTAINER Team PiggyCoin <team@piggy-coin.com>

# Simple usage with a mounted data directory:
# > docker build -t cosmos_gaia .
# > docker run -d -p 26656:26656 -p 26657:26657 -v ~/.gaiad:/root/.gaiad -v ~/.gaiacli:/root/.gaiacli cosmos_gaia
# > docker run -it cosmos_gaia gaiacli status

FROM golang:alpine AS build-env

# Set up version & dependencies
ENV CHECKOUT_VER=v2.0.3
ENV PACKAGES make git libc-dev bash gcc linux-headers eudev-dev curl

# Install minimum necessary dependencies, build Cosmos SDK, remove packages
RUN apk add --no-cache --update ca-certificates $PACKAGES && update-ca-certificates \
 && mkdir -p $GOPATH/src/github.com/cosmos \
 && cd $GOPATH/src/github.com/cosmos \
 && git clone https://github.com/cosmos/gaia \
 && cd $GOPATH/src/github.com/cosmos/gaia \
 && git checkout $CHECKOUT_VER \
 && make tools \
 && make build \
 && make install




FROM qlustor/alpine-runit
MAINTAINER Team PiggyCoin <team@piggy-coin.com>

ENV GAIAD_MONIKER=piggy-coin.com
ENV GAIAD_GENESIS=https://raw.githubusercontent.com/cosmos/launch/master/genesis.json

# Install ca-certificates
RUN apk-install --update wget ca-certificates && update-ca-certificates

# Copy over binaries from the build-env
COPY --from=build-env /go/bin/gaiad /usr/bin/gaiad
COPY --from=build-env /go/bin/gaiacli /usr/bin/gaiacli

ADD . /
RUN chmod a+x /etc/service/gaiad/run

# Ports - see https://forum.cosmos.network/t/what-ports-does-gaiad-use/444
# 26656 - p2p    26657 - Tendermint RPC    26658 - ABCI    26660 - stats    1317 - Light client
EXPOSE 26656
VOLUME /root/.gaiad
VOLUME /root/.gaiacli
WORKDIR /root/.gaiad
ENTRYPOINT ["/sbin/runit-docker"]
