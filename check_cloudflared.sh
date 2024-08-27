#!/bin/bash

# Command to check the status of the cloudflared service
STATUS_OUTPUT=$(systemctl status cloudflared 2>&1)

# Command to check the HTTP response code
HTTP_STATUS=$(curl -LIk -m 3 -X GET http://myserver/ -o /dev/null -w "%{http_code}\n" -s)

# Initialize a flag to indicate if a restart is needed
RESTART_NEEDED=false

# Check if the error "Unable to reach the origin service." is present in the systemctl output
if echo "$STATUS_OUTPUT" | grep -q "Unable to reach the origin service."; then
    echo "Error detected: Unable to reach the origin service."
    RESTART_NEEDED=true
fi

# Check if the HTTP status code is different from 200
if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "HTTP status code is $HTTP_STATUS, expected 200."
    RESTART_NEEDED=true
fi

# Restart the QEMU instance if needed
if [ "$RESTART_NEEDED" = true ]; then
    echo "Restarting QEMU instance..."
    /usr/bin/virsh reboot haos
    /usr/bin/wait
    /usr/bin/systemctl restart cloudflared.service
    if [ $? -eq 0 ]; then
        echo "QEMU instance restarted successfully."
    else
        echo "Failed to restart QEMU instance."
    fi
else
    echo "No issues detected. Cloudflared service and HTTP response are normal."
