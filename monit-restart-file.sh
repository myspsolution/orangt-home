#!/bin/bash
# /home/orangt/monit-restart-file.sh
# Usage: monit-restart-next.sh <SERVICE_NAME>
# Writes the service name to /tmp/monit-restart.txt (overwrites each time)

# Exit if no parameter
if [[ -z "$1" ]]; then
  echo "Usage: $0 <SERVICE_NAME>"
  exit 1
fi

SERVICE_NAME="$1"
echo "$SERVICE_NAME" > /tmp/monit-restart.txt
