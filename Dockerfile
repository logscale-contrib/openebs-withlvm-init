FROM docker.io/almalinux:9.1-minimal-20221201

RUN microdnf update -y ;\
    microdnf install nvme-cli util-linux lvm2  -y

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]