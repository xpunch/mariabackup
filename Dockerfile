FROM debian:9.12-slim

RUN set -x && \
    apt-get -qq update && \
    apt-get -qq install apt-transport-https curl awscli && \
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-10.1" && \
    apt-get -qq install mariadb-backup && \
    apt-get -qq autoclean && apt-get -qq autoremove && rm -rf /tmp/* /var/cache/apt/* /var/cache/depconf/*

ENV SOURCE_DIR=/var/lib/mysql \
    MYSQL_PORT=3306 \
    S3_REGION=us-east-1 \
    S3_PREFIX=backups

COPY backup.sh /bin/backup.sh
COPY restore.sh /bin/restore.sh
RUN chmod +x /bin/backup.sh && chmod +x /bin/restore.sh

CMD [ "backup.sh" ]