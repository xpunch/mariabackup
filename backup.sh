#!/usr/bin/env bash

set -e

MARIABACKUP="$(command -v mariabackup)"
if [[ ! -x "${MARIABACKUP}" ]]; then
    echo "${MARIABACKUP} is not executable!"
    exit 1
fi

if [ "${AWS_ACCESS_KEY_ID}" == "" ]; then
  echo "Warning: You did not set the AWS_ACCESS_KEY_ID environment variable."
fi

if [ "${AWS_SECRET_ACCESS_KEY}" == "" ]; then
  echo "Warning: You did not set the AWS_SECRET_ACCESS_KEY environment variable."
fi

if [ "${AWS_DEFAULT_REGION}" == "" ]; then
  echo "You need to set the AWS_DEFAULT_REGION environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" == "" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" == "" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" == "" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${ENCRYPT_KEY}" == "" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [[ ! -d "${SOURCE_DIR}" || ! "$(ls -A ${SOURCE_DIR})" ]]; then
    echo "directory '${SOURCE_DIR}' doesn't seem to contain a database"
    echo "check your env variable '\${SOURCE_DIR}' please"
    exit 1
fi

upload () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading ${SRC_FILE} ${DEST_FILE} on S3..."

  aws $AWS_ARGS s3 cp $SRC_FILE s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE

  if [ $? != 0 ]; then
    >&2 echo "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

BACKUP_FILE="/tmp/backup.xb.gz"
BACKUP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")

${MARIABACKUP} --no-version-check --backup --no-lock \
    --host=${MYSQL_HOST} \
    --port=${MYSQL_PORT} \
    --user=${MYSQL_USER} \
    --password=${MYSQL_PASSWORD} \
    --datadir=${SOURCE_DIR} \
    --stream=xbstream | gzip | openssl enc -aes-256-cbc -k ${ENCRYPT_KEY} > $BACKUP_FILE

if [ "${S3_FILE}" == "" ]; then
    S3_FILE="${BACKUP_START_TIME}.gz"
fi

upload $BACKUP_FILE $S3_FILE

echo "Backup finished"