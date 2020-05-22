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

if [ "${S3_FILE}" == "" ]; then
  echo "You need to set the S3_FILE environment variable."
  exit 1
fi

if [ "${ENCRYPT_KEY}" == "" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [[ -d "${SOURCE_DIR}" && "$(ls -A ${SOURCE_DIR})" ]]; then
    echo "directory '${SOURCE_DIR}' isn't empty"
    echo "check your env variable '\${SOURCE_DIR}' please"
    exit 1
fi

download () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Downloading ${SRC_FILE} ${DEST_FILE} on S3..."

  aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE

  if [ $? != 0 ]; then
    >&2 echo "Error downloading ${SRC_FILE} on S3"
  fi
}

TARGET_DIR=/tmp/backup
BACKUP_FILE="/tmp/backup.xb.gz"

download $S3_FILE $BACKUP_FILE
mkdir -p ${TARGET_DIR}
cd ${TARGET_DIR}
if [ "${ENCRYPT_KEY}" == "" ]; then
    gunzip -c ${BACKUP_FILE} | mbstream -x
else
    openssl  enc -d -aes-256-cbc -k ${ENCRYPT_KEY} -in ${BACKUP_FILE} | gzip -d | mbstream -x
fi
rm $BACKUP_FILE

${MARIABACKUP} --prepare --target-dir=${TARGET_DIR}

${MARIABACKUP} --copy-back --datadir=${SOURCE_DIR} --target-dir=${TARGET_DIR}

echo "Restore finished"