#!/bin/bash
#
# This script bulk enables or disables the protection mode for multiple LXC containers within a Proxmox VE environment.
# Protection mode prevents containers from being accidentally deleted or modified.
# This script is useful for managing the protection status of a group of containers efficiently.
#
# Usage:
# ./BulkToggleProtectionMode.sh <action> <start_ct_id> <num_cts>
#
# Arguments:
#   action      - The action to perform: "enable" or "disable".
#   start_ct_id - The starting container ID from which to begin.
#   num_cts     - The number of containers to update starting from start_ct_id.
#
# Example:
#   ./BulkToggleProtectionMode.sh enable 400 30
#   This command will enable protection for LXC containers with IDs from 400 to 429.
#
#   ./BulkToggleProtectionMode.sh disable 200 10
#   This command will disable protection for LXC containers with IDs from 200 to 209.

# Check if the required parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <action> <start_ct_id> <num_cts>"
    echo "  action: enable | disable"
    exit 1
fi

# Assigning input arguments
ACTION=$1
START_CT_ID=$2
NUM_CTS=$3

# Validate action
if [[ "$ACTION" != "enable" && "$ACTION" != "disable" ]]; then
    echo "Error: action must be either 'enable' or 'disable'."
    exit 1
fi

# Validate that START_CT_ID and NUM_CTS are integers
if ! [[ "$START_CT_ID" =~ ^[0-9]+$ ]] || ! [[ "$NUM_CTS" =~ ^[0-9]+$ ]]; then
    echo "Error: start_ct_id and num_cts must be positive integers."
    exit 1
fi

# Function to set protection
set_protection() {
    local id=$1
    local state=$2
    pct set "$id" --protected "$state"
}

# Determine the protection state
if [ "$ACTION" == "enable" ]; then
    PROTECTION_STATE=1
elif [ "$ACTION" == "disable" ]; then
    PROTECTION_STATE=0
fi

# Loop to set protection for each container
for (( i=0; i<$NUM_CTS; i++ )); do
    TARGET_CT_ID=$((START_CT_ID + i))
    
    # Check if the container exists
    if pct status "$TARGET_CT_ID" &> /dev/null; then
        echo "Setting protection to $ACTION for container ID $TARGET_CT_ID..."
        set_protection "$TARGET_CT_ID" "$PROTECTION_STATE"
        if [ $? -eq 0 ]; then
            echo "Successfully set protection to $ACTION for container ID $TARGET_CT_ID."
        else
            echo "Failed to set protection for container ID $TARGET_CT_ID."
        fi
    else
        echo "Container ID $TARGET_CT_ID does not exist. Skipping."
    fi
done

echo "Bulk protection configuration completed!"
