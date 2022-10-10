FROM docker.io/almalinux:9.0-minimal

RUN microdnf update -y ;\
    microdnf install nvme-cli util-linux lvm2  -y

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]