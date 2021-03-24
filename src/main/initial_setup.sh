#!/bin/sh

create_cluster_hosts() 
{
    MANAGER_IP=$1
    MANAGER_NAME=$2
    PRIMARY_IP=$3
    PRIMARY_NAME=$4
    BACKUP_IP=$5
    BACKUP_NAME=$6
    STANDBY_IP=$7 # Change this to an array of IPs later
    STANDBY_NAME=$8 # Change this to an array of IPs later

    # Add hard coded variables to file
    echo "# ------ FAILGUARD ------- #" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "# Failguard Manager Host - FGMH" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "$MANAGER_IP $MANAGER_NAME # Set by Failguard" >> /etc/cloud/templates/hosts.debian.tmpl 
    echo "# Failguard Main Cluster Host - FGMH" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "$PRIMARY_IP $PRIMARY_NAME # Set by Failguard" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "# Failguard Standby Cluster Hosts - FGSH" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "$STANDBY_IP $STANDBY_NAME # Set by Failguard" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "# Failguard Backup Host - FGBH" >> /etc/cloud/templates/hosts.debian.tmpl
    echo "$BACKUP_IP $BACKUP_NAME # Set by Failguard" >> /etc/cloud/templates/hosts.debian.tmpl
    # Iterate over multiple standby's
}

create_pgbackrest_config()
{
    OWNER=$1
    sudo chmod 755 /usr/bin/pgbackrest # Moved from the install_pgbackrest function
    # Create pgBackRest configuration file and directories
    sudo mkdir -p -m 770 /var/log/pgbackrest
    sudo chown $OWNER:$OWNER /var/log/pgbackrest
    sudo mkdir -p /etc/pgbackrest
    sudo mkdir -p /etc/pgbackrest/conf.d

    sudo touch /etc/pgbackrest/pgbackrest.conf
    sudo chmod 640 /etc/pgbackrest/pgbackrest.conf
    sudo chown $OWNER:$OWNER /etc/pgbackrest/pgbackrest.conf
} 

create_pgbackrest_repository()
{
    OWNER=$1
    # Create the pgBackRest repository
    sudo mkdir -p /var/lib/pgbackrest
    sudo chmod 750 /var/lib/pgbackrest
    sudo chown $OWNER:$OWNER /var/lib/pgbackrest
}