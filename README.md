# Mariabackup
[Mariabackup](https://mariadb.com/kb/en/mariabackup-overview/) is an open source tool provided by MariaDB for performing physical online backups of InnoDB, Aria and MyISAM tables.
This project used to backup mariadb and upload to S3 server or backup from file of S3 server.

# Usage
Backup
```
docker run -v "/var/lib/mysql:/var/lib/mysql" -e MYSQL_HOST= -e MYSQL_USER=root -e MYSQL_PASSWORD= -e S3_ENDPOINT= -e AWS_ACCESS_KEY_ID= -e AWS_SECRET_ACCESS_KEY= -e AWS_DEFAULT_REGION=us-east-1 -e S3_BUCKET= -e SOURCE_DIR=/var/lib/mysql mariabackup:10.4
```

Restore
```
docker run -v "/opt/mysql/data:/opt/mysql/data" -e MYSQL_HOST= -e MYSQL_USER=root -e MYSQL_PASSWORD= -e S3_ENDPOINT= -e AWS_ACCESS_KEY_ID= -e AWS_SECRET_ACCESS_KEY= -e AWS_DEFAULT_REGION=us-east-1 -e S3_BUCKET= -e SOURCE_DIR=/opt/mysql/data mariabackup:10.4 /bin/restore.sh
```
