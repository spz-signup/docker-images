# base information
FROM debian:buster
MAINTAINER Marco Neumann <marco@crepererum.net>

# versions
ENV LIBASR_VERSION="1.0.4" \
    OPENSMPTD_VERSION="6.8.0p2" \
    LIBASR_SHA512="6f189f9f492da8204396fe1246b4a0162751b2060a881469649ecf987b7ac1cc834193d2052e80a09bf94fedc8fc64123e9dfcfe3a2e4395f9e26d37afc84501" \
    OPENSMPTD_SHA512="48f152b75575146fdd09bdf47123041ea62fefb6e5de33a69826bf91a2126a918f8db1caffadb2f142a1a21de8126d492de88cb65bdf169e61c0b22d3e78d290"

# upgrade system and install deps
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends bison ca-certificates file gcc libevent-dev libssl-dev make wget build-essential libz-dev && \
    rm -rf /root/.cache /var/cache/*

# build opensmtpd and prepare system
RUN mkdir src && \
    cd src && \
    wget "https://www.opensmtpd.org/archives/libasr-$LIBASR_VERSION.tar.gz" && \
    wget "https://www.opensmtpd.org/archives/opensmtpd-$OPENSMPTD_VERSION.tar.gz" && \
    (echo "$LIBASR_SHA512 libasr-$LIBASR_VERSION.tar.gz" | sha512sum --check -) && \
    (echo "$OPENSMPTD_SHA512 opensmtpd-$OPENSMPTD_VERSION.tar.gz" | sha512sum --check -) && \
    tar xf libasr-$LIBASR_VERSION.tar.gz && \
    tar xf opensmtpd-$OPENSMPTD_VERSION.tar.gz && \
    cd libasr-$LIBASR_VERSION && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd ../opensmtpd-$OPENSMPTD_VERSION && \
    ./configure --prefix=/usr --with-path-CAfile=/etc/ssl/certs/ca-certificates.crt && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf src && \
    useradd --uid 1000 _smtpd && \
    useradd --uid 1001 _smtpq && \
    mkdir /var/empty

# expose only simple, unencrypted SMTP port
EXPOSE 25

# standard command
CMD ["/usr/sbin/smtpd", "-f", "/etc/smtpd.conf", "-d"]
