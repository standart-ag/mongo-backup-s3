#!/bin/bash
set -e

# Date function
get_date () {
    date +[%Y-%m-%d\ %H:%M:%S]
}

# Script
: ${GPG_KEYSERVER:='keyserver.ubuntu.com'}
: ${GPG_KEYID:=''}

if [ -z "$GPG_KEYID" ]
then
    echo "$(get_date) !WARNING! It's strongly recommended to encrypt your backups."
else
    echo "$(get_date) Preparing keys: importing from keyserver"
    gpg --keyserver ${GPG_KEYSERVER} --recv-keys ${GPG_KEYID}
fi

echo "$(get_date) Mongo backup started"

export MC_HOST_backup=$S3_URI

mc mb backup/${S3_BUCK} --insecure

if [ -z "$GPG_KEYID" ]
then
    mongodump --uri $MONGO_URI --archive | pigz -9 | mc pipe backup/${S3_BUCK}/${S3_NAME}-`date +%Y-%m-%d_%H-%M-%S`.archive.gz --insecure
else
    mongodump --uri $MONGO_URI --archive | pigz -9 \
     | gpg --encrypt -z 0 --recipient ${GPG_KEYID} --trust-model always \
     | mc pipe backup/${S3_BUCK}/${S3_NAME}-`date +%Y-%m-%d_%H-%M-%S`.archive.gz.pgp --insecure
fi

echo "$(get_date) Mongo backup completed successfully"
