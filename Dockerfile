FROM debian:10-slim

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /downloads /config/NZBGet /etc/openvpn /etc/nzbget

RUN apt update \
    && apt -y upgrade \
    && apt -y install --no-install-recommends \
    curl \
    jq \
    ca-certificates \
    && NZBGET_VERSION=$(curl -sX GET "https://api.github.com/repos/nzbget/nzbget/releases" | jq '.[] | select(.prerelease==false) | .name' | head -n 1 | tr -d '"') \
    && curl -o nzbget-${NZBGET_VERSION}-bin-linux.run -L https://github.com/nzbget/nzbget/releases/download/v${NZBGET_VERSION}/nzbget-${NZBGET_VERSION}-bin-linux.run \
    && chmod +x nzbget-${NZBGET_VERSION}-bin-linux.run \
    && ./nzbget-${NZBGET_VERSION}-bin-linux.run \
    && rm  nzbget-${NZBGET_VERSION}-bin-linux.run

RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \ 
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt -y install --no-install-recommends \
    iptables \
    inetutils-ping \
    procps \
    moreutils \
    net-tools \
    dos2unix \
    openvpn \
    openresolv \
    wireguard-tools \
    ipcalc \
    ca-certificates \
    && apt-get clean \
    && apt -y autoremove \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

VOLUME /config /downloads

ADD openvpn/ /etc/openvpn/
ADD nzbget/ /etc/nzbget/

RUN chmod +x /etc/nzbget/*.sh /etc/nzbget/*.init /etc/openvpn/*.sh

EXPOSE 6789
EXPOSE 6791
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
