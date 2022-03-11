#!/bin/bash

if [ "${POSTGRES_ENV_POSTGRES_PASSWORD}" == "**Random**" ]; then
        unset POSTGRES_ENV_POSTGRES_PASSWORD
fi

POSTGRES_HOST=${POSTGRES_PORT_5432_TCP_ADDR:-${POSTGRES_HOST}}
POSTGRES_HOST=${POSTGRES_PORT_1_5432_TCP_ADDR:-${POSTGRES_HOST}}
POSTGRES_PORT=${POSTGRES_PORT_5432_TCP_PORT:-${POSTGRES_PORT}}
POSTGRES_PORT=${POSTGRES_PORT_1_3306_TCP_PORT:-${POSTGRES_PORT}}
POSTGRES_USER=${POSTGRES_USER:-${POSTGRES_ENV_POSTGRES_USER}}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-${POSTGRES_ENV_POSTGRES_PASSWORD}}

[ -z "${POSTGRES_HOST}" ] && { echo "=> POSTGRES_HOST cannot be empty" && exit 1; }
[ -z "${POSTGRES_PORT}" ] && { echo "=> POSTGRES_PORT cannot be empty" && exit 1; }
[ -z "${POSTGRES_USER}" ] && { echo "=> POSTGRES_USER cannot be empty" && exit 1; }
[ -z "${POSTGRES_PASSWORD}" ] && { echo "=> POSTGRES_PASSWORD cannot be empty" && exit 1; }
[ -z "${POSTGRES_DB}" ] && { echo "=> POSTGRES_DB cannot be empty" && exit 1; }

export PGPASSWORD="${POSTGRES_PASSWORD}"

BACKUP_CMD="pg_dump -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -f /backup/\${BACKUP_NAME} ${EXTRA_OPTS} ${POSTGRES_DB}"


echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
MAX_BACKUPS=${MAX_BACKUPS}

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S).sql

export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "=>   Dump done"
    echo "=>   Deleting old dumps"

    if [ -n "\${MAX_BACKUPS}" ]; then
      while [ \$(ls /backup -N1 | wc -l) -gt \${MAX_BACKUPS} ];
      do
        BACKUP_TO_BE_DELETED=\$(ls /backup -N1 | sort | head -n 1)
        echo "=>   \${BACKUP_TO_BE_DELETED} wil be deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
      done
      echo "=>   Old dumps has been deleted"
      echo "=>   Backup done with successful"
    fi
else
    echo "=>  WARNING BACKUP FAILED - SEE LOGS"
    rm -rf /backup/\${BACKUP_NAME}
fi
EOF
chmod +x /backup.sh

echo "=> Creating restore script"
rm -f /restore.sh
cat <<EOF >> /restore.sh
#!/bin/bash
export PGPASSWORD="${POSTGRES_PASSWORD}"

echo "=> Restore database from \$1"
if psql -h${POSTGRES_HOST} -p${POSTGRES_PORT} -U${POSTGRES_USER} < \$1 ;then
    echo "   Restore succeeded"
else
    echo "   Restore failed"
fi
echo "=> Done"
EOF
chmod +x /restore.sh

touch /postgres_backup.log
tail -F /postgres_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
    echo "=> Restore latest backup"
    until nc -z $POSTGRES_HOST $POSTGRES_PORT
    do
        echo "waiting database container..."
        sleep 1
    done
    ls -d -1 /backup/* | tail -1 | xargs /restore.sh
fi

echo "${CRON_TIME} /backup.sh >> /postgres_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f
