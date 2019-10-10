FROM golang:1.13 as builder
LABEL stage=intermediate

#compile linux only

ENV \
    GOOS=linux \
    VOLANTMQ_WORK_DIR=/usr/lib/volantmq \
    VOLANTMQ_BUILD_FLAGS="-i" \
    VOLANTMQ_PLUGINS_DIR=/usr/lib/volantmq/plugins \
    GO111MODULE=off

RUN mkdir -p $VOLANTMQ_WORK_DIR/bin
RUN mkdir -p $VOLANTMQ_WORK_DIR/conf
RUN mkdir -p $VOLANTMQ_PLUGINS_DIR

# Create environment directory
ENV PATH $VOLANTMQ_WORK_DIR/bin:$PATH

# build server
RUN \
       go get -v github.com/ahmetb/govvv \
    && cd $GOPATH/src/github.com/VolantMQ/volantmq/cmd/volantmq \
    && go get -v github.com/VolantMQ/vlapi/... \
    && go get -v \
    && govvv build $VOLANTMQ_BUILD_FLAGS -o $VOLANTMQ_WORK_DIR/bin/volantmq

# build debug plugins
RUN \
       cd $GOPATH/src/github.com/VolantMQ/vlapi/vlplugin/debug \
    && go build $VOLANTMQ_BUILD_FLAGS -buildmode=plugin -o $VOLANTMQ_WORK_DIR/plugins/debug.so

# build health plugins
RUN \
    cd $GOPATH/src/github.com/VolantMQ/vlapi/vlplugin/health && \
    go build $VOLANTMQ_BUILD_FLAGS -buildmode=plugin -o $VOLANTMQ_WORK_DIR/plugins/health.so

#build persistence plugins
RUN \
    cd $GOPATH/src/github.com/VolantMQ/vlapi/vlplugin/vlpersistence/bbolt/plugin && \
    go build $VOLANTMQ_BUILD_FLAGS -buildmode=plugin -o $VOLANTMQ_WORK_DIR/plugins/persistence_bbolt.so

FROM ubuntu
ENV \
    VOLANTMQ_WORK_DIR=/usr/lib/volantmq

COPY --from=builder $VOLANTMQ_WORK_DIR $VOLANTMQ_WORK_DIR

# Create environment directory
ENV PATH $VOLANTMQ_WORK_DIR/bin:$PATH
ENV VOLANTMQ_PLUGINS_DIR=$VOLANTMQ_WORK_DIR/plugins

# default config uses mqtt:1883
EXPOSE 1883
CMD ["volantmq"]
