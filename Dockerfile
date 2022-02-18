FROM debian:bullseye-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/NZBGet /etc/openvpn /etc/nzbget

# Install NZBGet
RUN apt update \
    && apt -y upgrade \
    && apt -y install --no-install-recommends \
    curl \
    jq \
    ca-certificates \
    && NZBGET_VERSION_NAME=$(curl -sX GET "https://api.github.com/repos/nzbget/nzbget/releases" | jq '.[] | select(.prerelease==true) | .name' | head -n 1 | tr -d '"') \
    && NZBGET_TAG_NAME=$(curl -sX GET "https://api.github.com/repos/nzbget/nzbget/releases" | jq '.[] | select(.prerelease==true) | .tag_name' | head -n 1 | tr -d '"') \
    && curl -o nzbget-${NZBGET_VERSION_NAME}-bin-linux.run -L https://github.com/nzbget/nzbget/releases/download/${NZBGET_TAG_NAME}/nzbget-${NZBGET_VERSION_NAME}-bin-linux.run \
    && chmod +x nzbget-${NZBGET_VERSION_NAME}-bin-linux.run \
    && ./nzbget-${NZBGET_VERSION_NAME}-bin-linux.run \
    && rm nzbget-${NZBGET_VERSION_NAME}-bin-linux.run \
    && apt -y purge \
    curl \
    jq \
    ca-certificates \
    && apt-get clean \
    && apt -y autoremove \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install dependencies
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \ 
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && echo "deb http://deb.debian.org/debian/ bullseye non-free" > /etc/apt/sources.list.d/non-free-unrar.list \
    && printf 'Package: *\nPin: release a=non-free\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-non-free \
    && apt update \
    && apt -y install --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    kmod \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    p7zip-full \
    par2 \
    procps \
    unrar \
    unzip \
    wireguard-tools \
    zip \
    && apt-get clean \
    && apt -y autoremove \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Remove Expired Let's Encrypt Root Certificate
RUN sed -i '\~mozilla/DST_Root_CA_X3.crt~d' /etc/ca-certificates.conf \
    && update-ca-certificates

VOLUME /config /downloads

ADD openvpn/ /etc/openvpn/
ADD nzbget/ /etc/nzbget/

RUN chmod +x /etc/nzbget/*.sh /etc/nzbget/*.init /etc/openvpn/*.sh

EXPOSE 6789
EXPOSE 6791
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
