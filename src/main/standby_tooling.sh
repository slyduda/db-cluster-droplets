#!/bin/sh
# -------------------------- #
#   Standby Cluster Setup -  #
# -------------------------- #


# -------------------------- #
#  Standby Streaming Config  #
# -------------------------- #

set_streaming_standby_config()
{
       PRIMARY_NAME=$1
       BACKUP_NAME=$2
       REPLICATION_PASSWORD=$3
       CLUSTER_NAME=$4
       
       > /etc/pgbackrest/pgbackrest.conf
       echo "[$CLUSTER_NAME]
       pg1-path=/var/lib/postgresql/12/main
       recovery-option=primary_conninfo=host=pg-primary port=5432 user=replicator

       [global]
       log-level-file=detail
       repo1-host=$BACKUP_NAME" >> /etc/pgbackrest/pgbackrest.conf

       # Configure the replication password in the .pgpass file.
       sudo -u postgres sh -c 'echo \
              "$PRIMARY_NAME:*:replication:replicator:$REPLICATION_PASSWORD" \
              >> /var/lib/postgresql/.pgpass'

       sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass

       sudo pg_ctlcluster 12 $CLUSTER_NAME stop
       sudo -u postgres pgbackrest --stanza=$CLUSTER_NAME --delta --type=standby restore
       sudo -u postgres cat /var/lib/postgresql/12/main/postgresql.auto.conf

       # Start PostgreSQL
       sudo pg_ctlcluster 12 $CLUSTER_NAME start

       #Examine the PostgreSQL log output for log messages indicating success
       # sudo -u postgres cat /var/log/postgresql/postgresql-12-demo.log

       # Create a new table on the primary
       # Stuff
}