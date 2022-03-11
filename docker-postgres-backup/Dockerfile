FROM postgres:13.1
MAINTAINER Joan Marc Carbo <jmcarbo@gmail.com>

RUN apt-get update && \
    apt-get install -y wget curl netcat cron
RUN mkdir /backup

ENV CRON_TIME="0 0 * * *" \
    PG_DB="--all-databases"

ADD run.sh /run.sh
RUN chmod +x /run.sh
VOLUME ["/backup"]

CMD ["/run.sh"]
