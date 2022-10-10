FROM docker.io/almalinux:8.6-minimal

RUN microdnf update -y ;\
    microdnf install nvme-cli util-linux lvm2  -y

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]