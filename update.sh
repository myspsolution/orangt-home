#!/bin/bash
# update.sh
# update system script for Ubuntu/Debian for using with cronjob
# prepared by dicky.dwijanto@myspsolution.com
# last update: May 18th, 2025

RED='\033[1;41;37m'
BLU='\033[1;94m'
YLW='\033[1;33m'
STD='\033[0m'
BLD='\033[1;97m'

# Check if system is Debian/Ubuntu family
if ! grep -qiE 'ID=(ubuntu|debian)|ID_LIKE=.*debian' /etc/os-release; then
  OS_INFO=$(cat /etc/os-release | grep "^PRETTY_NAME=" | sed -n "s/^PRETTY_NAME[ ]*=//p" | xargs)
  echo ""
  echo -e "This script must be run on ${BLD}Ubuntu/Debian${STD} family only."
  echo -e "Your detected OS: ${BLD}${OS_INFO}${STD}"
  echo ""
  exit 1
fi

IS_SA=0
IS_SUDOER=0

# Check superadmin (EUID=0)
if [ $(id -u) -eq 0 ]; then
  IS_SA=1
fi

# Check sudoer
NOT_SUDOER=$(sudo -l -U $USER 2>&1 | egrep -c -i "not allowed to run sudo|unknown user")
if [ "${NOT_SUDOER}" -eq 0 ]; then
  IS_SUDOER=1
fi

if [ "${IS_SA}" -eq 0 ] && [ "${IS_SUDOER}" -eq 0 ]; then
  echo ""
  echo -e "Please run this script as ${BLD}sudoer or superadmin${STD}"
  echo ""
  exit 1
fi

# check if nginx is installed
if type nginx >/dev/null 2>&1; then
  NGINX_INSTALLED=true
else
  NGINX_INSTALLED=false
fi

echo ""

# stop nginx service if installed
if ${NGINX_INSTALLED}; then
  echo -e "Stopping ${BLD}nginx${STD} service temporarily..."
  [ "${IS_SA}" -eq 1 ] && systemctl stop nginx || sudo systemctl stop nginx
fi

[ "${IS_SA}" -eq 1 ] && rm -f /tmp/update.txt || sudo rm -f /tmp/update.txt

# update and upgrade packages
# var DEBIAN_FRONTEND to make operations non-interactive

if [ "${IS_SA}" -eq 1 ]; then
  DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade > /tmp/update.txt
  DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade >> /tmp/update.txt
else
  sudo DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade > /tmp/update.txt
  sudo DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade >> /tmp/update.txt
fi
# if [ "${IS_SA}" -eq 1 ]

# remove unnecessary packages and clean up
[ "${IS_SA}" -eq 1 ] && apt-get autoremove -y || sudo apt-get autoremove -y
[ "${IS_SA}" -eq 1 ] && apt-get clean -y || sudo apt-get clean -y
[ "${IS_SA}" -eq 1 ] && apt-get autoclean -y || sudo apt-get autoclean -y

if [ -f /var/run/reboot-required ] || grep -q '^NEEDRESTART-SVC:' /tmp/update.txt; then
  echo -e "${BLD}reboot is required to complete the updates${STD}."
  [ "${IS_SA}" -eq 1 ] && reboot || sudo reboot
else
  if ${NGINX_INSTALLED}; then
    echo -e "Restarting ${BLD}nginx${STD} service..."
    [ "${IS_SA}" -eq 1 ] && systemctl start nginx || sudo systemctl start nginx
    echo ""
  fi
fi
