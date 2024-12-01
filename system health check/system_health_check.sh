#!/bin/bash


# Author: Sivasankar MG
# Date: 2024-12-01
# Purpose: This script is used to check the system health.
# Usage: ./system_health_check.sh
# Example: ./system_health_check.sh


#!/bin/bash

# Variables
CPU_THRESHOLD=10
MEM_THRESHOLD=20
DISK_THRESHOLD=20
EMAIL="you@example.com"
REPORT_FILE="/var/log/system_health.log"

# Function for logging
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$REPORT_FILE"
}

# Check CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
if [ ${CPU_USAGE%.*} -gt $CPU_THRESHOLD ]
then
    log "High CPU Usage detected: $CPU_USAGE%" | mail -s "CPU Alert" "$EMAIL"
fi

# Check Memory Usage
MEM_USAGE=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100}')
if [ $MEM_USAGE -gt $MEM_THRESHOLD ]
then
    log "High Memory Usage detected: $MEM_USAGE%" | mail -s "Memory Alert" "$EMAIL"
fi


# Check Disk Usage
DISK_USAGE=$(df / | grep / | awk '{print $5}' | sed 's/%//g')
if [ $DISK_USAGE -gt $DISK_THRESHOLD ]
then
    log "High Disk Usage detected: $DISK_USAGE%" | mail -s "Storage Alert" "$EMAIL"
fi

log "System Health Check completed."
exit 0