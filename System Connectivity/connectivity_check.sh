#!/bin/bash


# Author: Sivasankar MG
# Date: 2024-11-30
# Purpose: This script is used to check connectivity of nodes.
# Usage: ./connectivity_check.sh <host_names_file>
# Example: ./connectivity_check.sh hosts

# Note: This script assumes that the host names are in the same directory as the script.


# Fuction to connectivity of nodes
function connectivity() {

    node=$1

    ping -c 3 $node &> /dev/null

    if [ $? -ne 0 ]
    then
        echo "$node is not reachable"
    else
        echo "$node is reachable"
    fi
}


# Main Script

host_names_file=$1

# check the valid no. of arguments
if [ $# -ne 1 ]
then
    echo "Usage: $0 <host_names file>"
    exit 1
fi

# check if the file exists
if [ ! -f $host_names_file ]
then
    echo "File $host_names_file does not exist"
    exit 2
fi

# Iterating the check for each node in the file
for host in $(cat $host_names_file)
do
    connectivity $host
done