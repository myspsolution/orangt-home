#!/bin/bash
# maintenance.sh
# scheduled maintenance script for using with cronjob
# prepared by dicky.dwijanto@myspsolution.com
# last update: Sept 23th, 2025
VERSION="1.1"

ORANGT_CONFIG_FILE="/etc/orangt.conf"

if [ -f "${ORANGT_CONFIG_FILE}" ]; then
  while IFS='=' read -r key value; do
    # Skip empty lines and lines starting with #
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

    # Remove leading/trailing spaces from key and value
    key="$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Export variable (optional: remove quotes if you want)
    export "$key"="$value"
  done < "${ORANGT_CONFIG_FILE}"
fi

if [ -z "${ORANGT_USER}" ]; then
  # default ORANGT_USER
  ORANGT_USER="orangt"
fi

if [ -z "${ORANGT_DIR}" ]; then
  # default ORANGT_DIR
  ORANGT_DIR="/var/www/html"
fi

if [ -z "${ORANGT_NGINX_LOG_DIR}" ]; then
  # default ORANGT_NGINX_LOG_DIR
  ORANGT_NGINX_LOG_DIR="/var/log/nginx"
fi

if [ -z "${ORANGT_SUPERVISOR_LOG_DIR}" ]; then
  # default ORANGT_SUPERVISOR_LOG_DIR
  ORANGT_SUPERVISOR_LOG_DIR="/var/log/supervisor"
fi

RED='\033[1;41;37m'
BLU='\033[1;94m'
YLW='\033[1;33m'
STD='\033[0m'
BLD='\033[1;97m'

echo ""
echo -e "${BLD}maintenance.sh${STD} version ${BLD}${VERSION}${STD}"

# Check if PHP is installed
if ! command -v php &> /dev/null; then
  echo ""
  echo -e "${BLD}PHP is not installed on this system${STD}. Exiting."
  echo ""
  exit 1
fi

# Check if composer is installed
#if ! command -v composer &> /dev/null; then
#  echo ""
#  echo -e "${BLD}composer is not installed on this system${STD}. Exiting."
#  echo ""
#  exit 1
#fi

# Check if the current user is ORANGT_USER
if [ "${USER}" != "${ORANGT_USER}" ]; then
  echo ""
  echo -e "Script must be run as user: ${BLD}${ORANGT_USER}${STD}. Exiting."
  echo ""
  exit 1
fi

IS_SUDOER=0
# Check sudoer
NOT_SUDOER=$(sudo -l -U $USER 2>&1 | egrep -c -i "not allowed to run sudo|unknown user")
if [ "${NOT_SUDOER}" -eq 0 ]; then
  IS_SUDOER=1
fi

if [ "${IS_SUDOER}" -eq 0 ]; then
  echo ""
  echo -e "Please run this script as ${BLD}sudoer${STD}"
  echo ""
  exit 1
fi

# Check if the directory ORANGT_DIR exists
if [ ! -d "${ORANGT_DIR}" ]; then
  echo ""
  echo -e "Directory ${BLD}${ORANGT_DIR}${STD} does not exist. Exiting."
  echo ""
  exit 1
fi

echo ""
echo -e "ORANGT_USER               : ${BLD}${ORANGT_USER}${STD}"
echo -e "ORANGT_DIR                : ${BLD}${ORANGT_DIR}${STD}"
echo -e "ORANGT_NGINX_LOG_DIR      : ${BLD}${ORANGT_NGINX_LOG_DIR}${STD}"
echo -e "ORANGT_SUPERVISOR_LOG_DIR : ${BLD}${ORANGT_SUPERVISOR_LOG_DIR}${STD}"
echo ""

PHP_DB_INDEXER="/home/${ORANGT_USER}/create_db_indexes.php"

# Loop through the results of find command
find "${ORANGT_DIR}" -type f -name artisan | while read -r ARTISAN_FILE; do
  # Get the directory part of the artisan file
  DIR_PROJECT=$(dirname "$ARTISAN_FILE")

  # Echo the directory
  echo -e "${BLD}${DIR_PROJECT}${STD}"

  # Change ownership of the directory to orangt:orangt
  # echo "chown -R ${ORANGT_USER}:${ORANGT_USER} ${DIR_PROJECT}"
  # chown -R "${ORANGT_USER}:${ORANGT_USER}" "${DIR_PROJECT}"

  # Navigate to the project directory
  echo "cd ${DIR_PROJECT}"
  cd "${DIR_PROJECT}" || exit

  if [ -f "${PHP_DB_INDEXER}" ]; then
    # do some indexing when required
    echo "php ${PHP_DB_INDEXER} ${DIR_PROJECT}/.env execute"
    php "${PHP_DB_INDEXER}" "${DIR_PROJECT}/.env" execute
  fi

  LARAVEL_DIR_LOG="${DIR_PROJECT}/storage/logs"

  if [ -d "${LARAVEL_DIR_LOG}" ]; then
    echo "sudo find ${LARAVEL_DIR_LOG} -type f -name '*.log' -mtime +2 -delete"
    sudo find "${LARAVEL_DIR_LOG}" -type f -name '*.log' -mtime +2 -delete
  fi

  LARAVEL_DIR_TEMP="${DIR_PROJECT}/storage/app/public/temp"
  if [ -d "${LARAVEL_DIR_TEMP}" ]; then
    echo "sudo find ${LARAVEL_DIR_TEMP} -type f -mtime +1 -delete"
    sudo find "${LARAVEL_DIR_TEMP}" -type f -mtime +1 -delete
  fi

  # Run the artisan optimize:clear command
  echo "php artisan optimize:clear"
  php -d error_reporting=E_ERROR artisan optimize:clear 2>/dev/null
done

if [ -d "${ORANGT_NGINX_LOG_DIR}" ]; then
  echo ""
  echo -e "Cleaning old log files on ${BLD}$ORANGT_NGINX_LOG_DIR${STD} :"
  echo "sudo find ${ORANGT_NGINX_LOG_DIR} -type f -mtime +2 -delete"
  sudo find "${ORANGT_NGINX_LOG_DIR}" -type f -mtime +2 -delete
fi

if [ -d "${ORANGT_SUPERVISOR_LOG_DIR}" ]; then
  echo ""
  echo -e "Cleaning old log files on ${BLD}${ORANGT_SUPERVISOR_LOG_DIR}${STD} :"
  echo "sudo find ${ORANGT_SUPERVISOR_LOG_DIR} -type f -mtime +2 -delete"
  sudo find "${ORANGT_SUPERVISOR_LOG_DIR}" -type f -mtime +2 -delete
fi

THE_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

sudo rm -f /tmp/maintenance.txt
echo "${THE_DATETIME}" > /tmp/maintenance.txt

echo ""
cat /tmp/maintenance.txt

echo ""
