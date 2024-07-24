#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Verify script is being run on PVE
if ! pveversion; then
	echo "Proxmox Virtual Environment not detected..."
	exit 1;
fi 

# check pve version
PVE_VERSION=$(pveversion | cut -d " " -f1 | cut -d "/" -f2 | cut -d "." -f1)
if [[ $PVE_VERSION -ne 8 ]]; then
    echo "Proxmox Virtual Environment must be version 8 for this script to run, please update..."
    exit 1
fi

function configure-repositories(){
    
    # delete enterprise repos
    if [ -n "$(find /etc/apt/sources.list.d/ -mindepth 1 -maxdepth 1)" ]; then
        echo "enterpise repos detected..."
        rm -rv /etc/apt/sources.list.d/*
    fi
    # overwrite new repos to /etc/apt/sources.list
    echo "deb http://ftp.debian.org/debian bookworm main contrib
    deb http://ftp.debian.org/debian bookworm-updates main contrib

    # Proxmox VE pve-no-subscription repository provided by proxmox.com,
    # NOT recommended for production use
    deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription

    # security updates
    deb http://security.debian.org/debian-security bookworm-security main contrib" > /etc/apt/sources.list

    # update system
    echo "updating system..."
    apt-get update > /dev/null
    apt-get install fail2ban -y > /dev/null
    apt-get upgrade -y > /dev/null
    echo "updates complete..."

}

function configure-groups(){
    
    # create administrators group and assign permissions
    if [[ -z "$(pveum group list | grep administrators)" ]]; then
        echo "creating administrators group with 'Administrator' permissions"
        pveum group add administrators
        pveum acl modify / -group administrators -role Administrator
    fi

    # create auditors group and assign permissions
    if [[ -z "$(pveum group list | grep auditors)" ]]; then
        echo "creating auditors group with 'PVEAuditor' permissions"
        pveum group add auditors
        pveum acl modify / -group auditors -role PVEAuditor
    fi

}

function remove-subscription-warning(){

    sed -Ezi.bak "s/(function\(orig_cmd\) \{)/\1\n\torig_cmd\(\);\n\treturn;/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

}

function configure-fail2ban(){
    
    # delete default template
    if [[ -e "/etc/fail2ban/jail.conf" ]]; then
        rm /etc/fail2ban/jail.conf
    fi

    # configure basic configuration for pve service
    F2B_CONFIG="[sshd]
    port    = ssh
    backend = systemd

    [proxmox]
    enabled = true
    port = https,http,8006
    filter = proxmox
    backend = systemd
    maxretry = 3
    findtime = 2d
    bantime = 1h"

    echo "$F2B_CONFIG"  > /etc/fail2ban/jail.local

    # configure basic filter for this service
    F2B_FILTER="[Definition]
    failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
    ignoreregex =
    journalmatch = _SYSTEMD_UNIT=pvedaemon.service"

    echo "$F2B_FILTER"  > /etc/fail2ban/filter.d/proxmox.conf

    systemctl restart fail2ban

    # testing ssh logins
    #fail2ban-regex systemd-journal /etc/fail2ban/filter.d/sshd.conf

    # testing proxmox api logins
    #fail2ban-regex systemd-journal /etc/fail2ban/filter.d/proxmox.conf

}

finish() {
  result=$?
    printf "pve-init.bash completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}

configure-repositories
configure-groups 
remove-subscription-warning 
configure-fail2ban 
trap finish EXIT ERR
