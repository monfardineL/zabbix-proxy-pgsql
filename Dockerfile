# syntax=docker/dockerfile:1.6
ARG OS_BASE_IMAGE=ubuntu:24.04
ARG MAJOR_VERSION=7.4
ARG ZBX_VERSION=${MAJOR_VERSION}.8

# Stage 0: Build Zabbix Proxy from source
FROM ${OS_BASE_IMAGE} AS builder

ARG MAJOR_VERSION
ARG ZBX_VERSION
ARG ZBX_SOURCES=https://cdn.zabbix.com/zabbix/sources/stable/${MAJOR_VERSION}/zabbix-${ZBX_VERSION}.tar.gz

ENV ZBX_SOURCES_DIR=/tmp/zabbix-${ZBX_VERSION} \
    ZBX_OUTPUT_DIR=/tmp/zabbix-${ZBX_VERSION}-output \
    DB_TYPE=postgresql \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        gcc \
        libc6-dev \
        make \
        pkg-config \
        libssh-dev \
        libevent-dev \
        libpcre2-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libsnmp-dev \
        libpq-dev \
        libopenipmi-dev \
        libldap2-dev \
        libmodbus-dev \
        libsqlite3-dev \
        unixodbc-dev \
        zlib1g-dev \
        wget \
        tar \
        ca-certificates \
        gzip && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux && \
    wget -4 -qO zabbix.tar.gz "${ZBX_SOURCES}" && \
    mkdir -p "${ZBX_SOURCES_DIR}" && \
    tar -xzf zabbix.tar.gz -C "${ZBX_SOURCES_DIR}" --strip-components=1 && \
    cd "${ZBX_SOURCES_DIR}" && \
    ./configure \
        --datadir=/usr/lib \
        --libdir=/usr/lib/zabbix \
        --prefix=/usr \
        --sysconfdir=/etc/zabbix \
        --enable-ipv6 \
        --enable-agent \
        --enable-proxy \
        --with-ldap \
        --with-libcurl \
        --with-libmodbus \
        --with-libpcre2 \
        --with-libxml2 \
        --with-postgresql \
        --with-net-snmp \
        --with-openipmi \
        --with-openssl \
        --with-ssh \
        --with-unixodbc \
        --silent && \
    make -j"$(nproc)" -s && \
    mkdir -p "${ZBX_OUTPUT_DIR}/proxy/sbin" "${ZBX_OUTPUT_DIR}/proxy/conf" "${ZBX_OUTPUT_DIR}/proxy/database/postgresql" \
             "${ZBX_OUTPUT_DIR}/general/bin" && \
    cp src/zabbix_proxy/zabbix_proxy "${ZBX_OUTPUT_DIR}/proxy/sbin/" && \
    cp conf/zabbix_proxy.conf "${ZBX_OUTPUT_DIR}/proxy/conf/zabbix_proxy.conf.dist" && \
    cp src/zabbix_get/zabbix_get "${ZBX_OUTPUT_DIR}/general/bin/" && \
    cp src/zabbix_sender/zabbix_sender "${ZBX_OUTPUT_DIR}/general/bin/" && \
    cat "database/${DB_TYPE}/schema.sql" > "database/${DB_TYPE}/create.sql" && \
    gzip -c "database/${DB_TYPE}/create.sql" > "${ZBX_OUTPUT_DIR}/proxy/database/${DB_TYPE}/create.sql.gz"

# Stage 1: Final image
FROM ${OS_BASE_IMAGE}

ARG MAJOR_VERSION
ARG ZBX_VERSION

ENV TERM=xterm \
    ZBX_VERSION=${ZBX_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    MIBDIRS=/usr/share/snmp/mibs:/var/lib/zabbix/mibs MIBS=+ALL \
    NMAP_PRIVILEGED= \
    ZABBIX_USER_HOME_DIR=/var/lib/zabbix \
    ZABBIX_CONF_DIR=/etc/zabbix

ENV ZBX_DB_NAME=dummy_db_name \
    ZBX_FPINGLOCATION=/usr/bin/fping \
    ZBX_LOADMODULEPATH=${ZABBIX_USER_HOME_DIR}/modules \
    ZBX_SNMPTRAPPERFILE=${ZABBIX_USER_HOME_DIR}/snmptraps/snmptraps.log \
    ZBX_SSHKEYLOCATION=${ZABBIX_USER_HOME_DIR}/ssh_keys/ \
    ZBX_SSLCERTLOCATION=${ZABBIX_USER_HOME_DIR}/ssl/certs/ \
    ZBX_SSLKEYLOCATION=${ZABBIX_USER_HOME_DIR}/ssl/keys/ \
    ZBX_SSLCALOCATION=${ZABBIX_USER_HOME_DIR}/ssl/ssl_ca/

LABEL org.opencontainers.image.authors="Alexey Pustovalov <alexey.pustovalov@zabbix.com>" \
      org.opencontainers.image.description="Zabbix proxy with PostgreSQL database support" \
      org.opencontainers.image.documentation="https://www.zabbix.com/documentation/${MAJOR_VERSION}/manual/installation/containers" \
      org.opencontainers.image.licenses="AGPL v3.0" \
      org.opencontainers.image.title="Zabbix proxy (PostgreSQL)" \
      org.opencontainers.image.url="https://zabbix.com/" \
      org.opencontainers.image.vendor="Zabbix SIA" \
      org.opencontainers.image.version="${ZBX_VERSION}"

STOPSIGNAL SIGTERM

COPY --from=builder /tmp/zabbix-${ZBX_VERSION}-output/proxy/sbin/zabbix_proxy /usr/sbin/zabbix_proxy
COPY --from=builder /tmp/zabbix-${ZBX_VERSION}-output/proxy/conf/zabbix_proxy.conf.dist ${ZABBIX_CONF_DIR}/zabbix_proxy.conf
COPY --from=builder /tmp/zabbix-${ZBX_VERSION}-output/proxy/database/postgresql/ /usr/share/doc/zabbix-proxy-postgresql/
COPY --from=builder /tmp/zabbix-${ZBX_VERSION}-output/general/bin/zabbix_get /usr/bin/
COPY --from=builder /tmp/zabbix-${ZBX_VERSION}-output/general/bin/zabbix_sender /usr/bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        fping \
        iputils-ping \
        libcurl4 \
        libevent-2.1-7t64 \
        libevent-core-2.1-7t64 \
        libevent-pthreads-2.1-7t64 \
        libevent-extra-2.1-7t64 \
        libmodbus5 \
        libopenipmi0 \
        libpq5 \
        libsnmp40t64 \
        libssh-4 \
        libxml2 \
        libpcre2-8-0 \
        libldap2 \
        unixodbc \
        zlib1g \
        nmap \
        traceroute \
        postgresql-client \
        gzip && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system --gid 1995 zabbix && \
    useradd --system --comment "Zabbix monitoring system" -g zabbix --uid 1997 --shell /sbin/nologin --home-dir ${ZABBIX_USER_HOME_DIR} zabbix && \
    mkdir -p ${ZABBIX_CONF_DIR} \
        ${ZABBIX_USER_HOME_DIR} \
        ${ZABBIX_USER_HOME_DIR}/enc \
        ${ZABBIX_USER_HOME_DIR}/enc_internal \
        ${ZABBIX_USER_HOME_DIR}/mibs \
        ${ZABBIX_USER_HOME_DIR}/modules \
        ${ZABBIX_USER_HOME_DIR}/snmptraps \
        ${ZABBIX_USER_HOME_DIR}/ssh_keys \
        ${ZABBIX_USER_HOME_DIR}/ssl \
        ${ZABBIX_USER_HOME_DIR}/ssl/certs \
        ${ZABBIX_USER_HOME_DIR}/ssl/keys \
        ${ZABBIX_USER_HOME_DIR}/ssl/ssl_ca \
        /usr/lib/zabbix/externalscripts && \
    chown --quiet -R zabbix:0 ${ZABBIX_CONF_DIR}/ ${ZABBIX_USER_HOME_DIR}/ && \
    chmod -R g=u ${ZABBIX_CONF_DIR}/ ${ZABBIX_USER_HOME_DIR}/ && \
    /usr/sbin/zabbix_proxy -V

EXPOSE 10051/tcp

WORKDIR ${ZABBIX_USER_HOME_DIR}

VOLUME ["${ZABBIX_USER_HOME_DIR}/snmptraps"]

COPY docker-entrypoint.sh /usr/bin/

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

USER 1997

CMD ["/usr/sbin/zabbix_proxy", "--foreground", "-c", "/etc/zabbix/zabbix_proxy.conf"]
