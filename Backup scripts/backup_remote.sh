#!/bin/bash


# Author: Sivasankar MG
# Date: 2024-12-01
# Purpose: This script is used to create backup in the remote system.
# Usage: ./backup_remote.sh <source> <destination>
# Example: ./backup_remote.sh docs backups

#Note: Make sure that passwordless authentication is enabled to remote system


# Variables
SOURCE_DIR=$1
DEST_DIR=$2
REMOTE_USER="remote_user"
REMOTE_HOST="remote_host"
REMOTE_PATH="/remote/path"
LOG_FILE="/var/log/backup.log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TAR_FILE="/tmp/backup_$DATE.tar.gz"
EMAIL="you@example.com"

# Function for logging
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}


# check the no. of valid arguments
if [ $# -ne 2 ]
then
    echo "Usage: ./backup.sh <source> <destination>"
    exit 1
fi

# check if the source and destination directories exist
if [ ! -d "$SOURCE_DIR" ] || [ ! -d "$DEST_DIR" ]
then
    echo "Source or destination directory does not exist"
    exit 1
fi


# check the presence of rsync
if [ ! command -v rsync &> /dev/null ]
then
    echo "rsync is to be installed to take backups..."
    echo "Install it based on your distribution..."
    exit 1
fi

# Compress files
log "Starting compression..."
tar -czf "$TAR_FILE" "$SOURCE_DIR" || { log "Compression failed!"; exit 1; }
log "Compression completed."

# Transfer files
log "Starting file transfer..."
rsync -avz "$TAR_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" || {
    log "File transfer failed!";
    echo "Backup failed" | mail -s "Backup Error" "$EMAIL";
    exit 1;
}
log "File transfer completed."

# Cleanup local backup
rm -f "$TAR_FILE"
log "Temporary backup file removed."

# Notify completion
echo "Backup successful: $TAR_FILE transferred to $REMOTE_HOST" | mail -s "Backup Completed" "$EMAIL"
log "Backup completed successfully."
