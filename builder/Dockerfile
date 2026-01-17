FROM openwrt/sdk:x86_64-generic-v22.03.7

RUN opkg update && \
    opkg install wget curl && \
    rm -rf /tmp/*

WORKDIR /builder

COPY . /packages

RUN rm -rf /packages/.git /packages/.github /packages/README.md

CMD ["/bin/sh"]
