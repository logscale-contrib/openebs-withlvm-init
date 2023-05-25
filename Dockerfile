FROM docker.io/alpine:3.18.0

RUN apk update ;\
    apk add nvme-cli lvm2 jq bash

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]