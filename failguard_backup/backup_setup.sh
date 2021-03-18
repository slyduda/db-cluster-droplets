#!/bin/sh
# -------------------------- #
#   Backup Cluster Config -  #
# -------------------------- #

configure_backup_server() 
{
    # Create a pgbackrest user to make it easier
    sudo adduser --disabled-password --gecos "" pgbackrest

    # Copy pgBackRest binary from build host
    sudo scp $buildHost:/build/pgbackrest-release-2.32/src/pgbackrest /usr/bin
    sudo chmod 755 /usr/bin/pgbackrest

    # Create pgBackRest configuration file and directories
    sudo mkdir -p -m 770 /var/log/pgbackrest
    sudo chown pgbackrest:pgbackrest /var/log/pgbackrest
    sudo mkdir -p /etc/pgbackrest
    sudo mkdir -p /etc/pgbackrest/conf.d
    sudo touch /etc/pgbackrest/pgbackrest.conf
    sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
    sudo chown pgbackrest:pgbackrest /etc/pgbackrest/pgbackrest.conf

    # Create the pgBackRest repository
    sudo mkdir -p /var/lib/pgbackrest
    sudo chmod 750 /var/lib/pgbackrest
    sudo chown pgbackrest:pgbackrest /var/lib/pgbackrest
}

# -------------------------- #
#  - Backup Cluster Auth --  #
# -------------------------- #

create_backup_keys() 
{
    # Create repository host key pair
    # Check if keypair already exists
    sudo -u pgbackrest mkdir -m 750 /home/pgbackrest/.ssh
    sudo -u pgbackrest ssh-keygen -f /home/pgbackrest/.ssh/id_rsa -t rsa -b 4096 -N ""
}

# -------------------------- #
#   HANG HERE@@@@@@@@@@@@@@  #
# -------------------------- #

copy_backup_key()
{
    HOST=$1
    # Copy pg-primary public key to pg-backup
    (echo -n 'no-agent-forwarding,no-X11-forwarding,no-port-forwarding,' && \
        echo -n 'command="/usr/bin/pgbackrest ${SSH_ORIGINAL_COMMAND#* }" ' && \
        sudo ssh root@$HOST cat /var/lib/postgresql/.ssh/id_rsa.pub) | \
        sudo -u pgbackrest tee -a /home/pgbackrest/.ssh/authorized_keys

    # Test connection from pg-backup to pg-primary
    sudo -u pgbackrest ssh -q postgres@$HOST exit
    if [ $? -ne 0 ]; then
        echo "Connection to $HOST failed."
        exit
    else
        echo "Connection to $HOST was successful."
}

copy_backup_key db-primary

# -------------------------- #
#  - Backup Cluster Repo --  #
# -------------------------- #

create_backup_config()
{
    # Configure pg1-host/pg1-host-user and pg1-path
    CLUSTER_NAME=$1
    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
    pg1-host=pg-primary
    pg1-path=/var/lib/postgresql/12/main

    [global]
    repo1-path=/var/lib/pgbackrest
    repo1-retention-full=2
    start-fast=y" >> /etc/pgbackrest/pgbackrest.conf

    # Test connection from pg-backup to pg-primary
    sudo -u pgbackrest ssh postgres@pg-primary
}

create_backup_config $CLUSTER_NAME
# -------------------------- #
#   HANG HERE@@@@@@@@@@@@@@  #
# -------------------------- #

copy_backup_key db-standby-6sdfm03fa


# -------------------------- #
#   HANG HERE@@@@@@@@@@@@@@  #
# -------------------------- #

# After standby is completely setup


# -------------------------- #
#  - Backup from Standby --  #
# -------------------------- #

create_backup_standby_config()
{
    CLUSTER_NAME=$1
    # On the backup
    > /etc/pgbackrest/pgbackrest.conf
    echo "[$CLUSTER_NAME]
    pg1-host=pg-primary
    pg1-path=/var/lib/postgresql/12/main
    pg2-host=pg-standby-1
    pg2-path=/var/lib/postgresql/12/main

    [global]
    backup-standby=y
    process-max=3
    repo1-path=/var/lib/pgbackrest
    repo1-retention-full=2
    start-fast=y" >> /etc/pgbackrest/pgbackrest.conf
}

create_backup_standby_config $CLUSTER_NAME