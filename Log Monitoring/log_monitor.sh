#!/bin/bash



# Author: Sivasankar MG
# Date: 2024-12-01
# Purpose: This script is used to monitor a log file and sends alert to admin through mail if there is any error.
# Usage: ./log_monitor.sh <log_files>
# Example: .log_monitor.sh logs

# Variables
LOG_FILES=$1
PATTERN="ERROR"
ALERT_EMAIL="you@example.com"
MONITORING_LOG="/var/log/monitoring_log.log"

# Function for logging
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$MONITORING_LOG"
}


#Check if file containing path of log files is provided as argument
if [ $# -ne 1 ]
then
    echo "Usage: $0 <logs_list_file>"
    exit 1
fi


# Check if the file exists
if [ ! -f "$LOG_FILES" ]
then
  echo "Logs list file '$LOG_FILES' not found."
  exit 1
fi

# Monitor log file
log "Starting log monitoring for pattern '$PATTERN'..."

for LOG_FILE in $(cat $LOG_FILES)
do
    tail -F "$LOG_FILE" | while read -r line; do
        if echo "$line" | grep -q "$PATTERN"; then
            log "Pattern matched: $line"
            echo "Log Alert: $line" | mail -s "Log Alert: Pattern Detected" "$ALERT_EMAIL"
        fi
    done
done