#!/bin/bash

# Author: Sivasankar MG
# Date: 2024-11-30
# Purpose: This script is used to create a new user in the system.
# Usage: ./create_user.sh <users_list_file>
# Example: ./create_user.sh users_list

# Note: The input file should contain the username and groups separated by ';'.
# Example: user1;group1,group2


# Define the file paths for the logfile, and the password file
INPUT_FILE="$1"
LOG_FILE="/var/log/user_creation.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"


# Ensure script is run with root privileges
if [ $EUID -ne 0 ]
then
    echo "Execute the script with sudo privilege or as root user"
    exit 1
fi

#Check if user list file path is provided as argument
if [ $# -ne 1 ]
then
    echo "Usage: $0 <users_list_file>"
    exit 1
fi


# Check if user list file exists
if [ ! -f "$INPUT_FILE" ]
then
  echo "User list file '$INPUT_FILE' not found."
  exit 1
fi

# Function to generate logs
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Create the log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]
then
    touch "$LOG_FILE"
    chmod 0600 "$LOG_FILE"
    log_message "Log file created: $LOG_FILE"
fi

# Create the password file if it doesn't exist
if [ ! -f "$PASSWORD_FILE" ]
then
    mkdir -p /var/secure
    touch "$PASSWORD_FILE"
    chmod 0600 "$PASSWORD_FILE"
    log_message "Password file created: $PASSWORD_FILE"
fi

# Function to generate a random Psuedo password
generate_password() {
    openssl rand -base64 12
}


# Read the input file line by line and save them into variables
while IFS=';' read -r user groups || [ -n $user ]; do

    user=$(echo "$user" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if the personal group exists, create one if it doesn't
    if getent group $user &> /dev/null ;
    then
        log_message "Personal Group $user already exists."
    else
        groupadd $user
        log_message "Personal Group '$user' created."
    fi

    # Check if the user exists
    if id -u $user &> /dev/null ;
    then
        log_message "$user already exists."
    else
        useradd -m -g $user -s /bin/bash "$user"
        log_message "User '$user' created."
    fi

    # Check if the groups were specified
    if [ -n $groups ]
    then
        
        IFS=',' read -r -a group_array <<< "$groups"

        for group in "${group_array[@]}"; do
            group=$(echo "$group" | xargs)

            # Check if the group exists
            if getent group $group &> /dev/null ;
            then
                log_message "Group $group already exists."
            else
                groupadd $group
                log_message "Group $group created."
            fi

            usermod -aG "$group" "$user"
            log_message "User '$user' added to group '$group'."
        done
    fi

    # Create and set a user password
    password=$(generate_password)
    echo "$user:$password" | chpasswd
    # Save user and password to a file
    echo "$user,$password" >> $PASSWORD_FILE

done < $INPUT_FILE


echo "Users have been created and added to their groups successfully"
