#!/bin/bash
# /home/orangt/monit-restart-service.sh
# restart service

RESTART_FILE="/tmp/monit-restart.txt"

# Priority: start first, then stop
if [[ -f "${RESTART_FILE}" ]]; then
  SERVICE_NAME=$(head -n 1 "${RESTART_FILE}" | xargs)
  sudo rm -f "${RESTART_FILE}"
  if [[ -n "${SERVICE_NAME}" ]]; then
    echo "$(date '+%F %T') - restart service: ${SERVICE_NAME}" | sudo tee -a /var/log/monit-restart-service.log > /dev/null
    echo "stopping monit temporarily"
    sudo systemctl stop monit
    echo "killing service: ${SERVICE_NAME}"
    sudo systemctl kill "${SERVICE_NAME}"
    sudo systemctl stop "${SERVICE_NAME}"
    echo "restarting service: ${SERVICE_NAME}"
    sudo systemctl restart "${SERVICE_NAME}"
    echo "restarting monit"
    sudo systemctl start monit
  else
   echo "[$(date '+%F %T')] ERROR: Empty service name in ${RESTART_FILE}"
  fi
else
  echo "[$(date '+%F %T')] No restart service file found: ${RESTART_FILE}"
fi
