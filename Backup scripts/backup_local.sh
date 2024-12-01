#!/bin/bash


# Author: Sivasankar MG
# Date: 2024-11-30
# Purpose: This script is used to create backup in the same system.
# Usage: ./backup.sh <source> <destination>
# Example: ./backup.sh docs backups


# check the no. of valid arguments
if [ $# -ne 2 ]
then
    echo "Usage: ./backup.sh <source> <destination>"
    exit 1
fi

# check the presence of rsync
if [ ! command -v rsync > /dev/null 2> /dev/null ]
then
    echo "rsync is to be installed to take backups..."
    echo "Install it based on your distribution..."
    exit 2
fi

curr_date=$(date +%Y-%m-%d)

rsync_options="-avb --backup-dir ../$2/$curr_date --delete" # --dry-run can be added to create a simulation to check the expected way of working.

$(which rsync) $rsync_options $1 $2/current >> backup_$curr_date.log








