#!/bin/bash


# Author: Sivasankar MG
# Date: 2024-12-01
# Purpose: This script is used to delete a user or group in the system.
# Usage: ./delete_users_groups.sh <target> <file>
# Example: ./delete_users_groups.sh user user_list
# Example: ./delete_users_groups.sh group group_list


LOG_FILE="/var/log/user_group_deletion.log"
TARGET=$1  # user or group
FILE=$2    # user or group list file

# Function for logging
log(){
    echo "$(date '+%Y-%m%d %H:%M:%S ') - $1" >> $LOG_FILE
}

# Function for deleting user
del_user(){

    user=$1

    if id "$user" &> /dev/null ;
    then
        userdel -r "$user" && log "User $user deleted successfully." || log "Failed to delete user $user"
    else
        log "User $user doesn't exist"
    fi

}


# Function for deleting group
del_group(){

    group=$1

    if getent group "$group" &>/dev/null; then
        # Ensure no users belong to the group before deletion
        GROUP_USERS=$(getent group "$group" | awk -F: '{print $4}')
        if [[ -n $GROUP_USERS ]]; 
        then
            log "Group $group cannot be deleted because it has members: $GROUP_USERS."
            return 1
        fi

        groupdel "$group" && log "Group $group deleted successfully." || log "Failed to delete group $group."
    else
        log "Group $group doesn't exist."
    fi

}



if [ $# -ne 2 ]
then
    echo "Usage: $0 <target> <file>"
    exit 1
fi

if [ ! -f $FILE ]
then
    echo "File $FILE not found"
    exit 1
fi

# Perform deletion based on the target type
case $TARGET in 
    user)
        for usr in $(cat $FILE) 
        do
            del_user $usr
        done
    ;;
    group)
        for grp in $(cat $FILE) 
        do
            del_group $grp
        done
    ;;
    *)
        echo "Invalid target type. Use 'user' or 'group' "
        log "Invalid target type $TARGET"
        exit 1
    ;;
esac