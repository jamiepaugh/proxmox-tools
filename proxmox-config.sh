#!/bin/bash
IS_PBS=false
IS_PVE=false

function detect-version() {

	# Checks which Proxmox product is installed
	if pveversion; then
		echo "pveversion ran succesfully"
		IS_PVE=true
	else
		echo "pveversion did not run"
		IS_PBS=true
	fi
}

function configure-sources() {

	# Removes default source list
    # Replaces source list based on Proxmox installation
    local -r  sources=/etc/apt/sources.list 
    local -r  custom_pbs=./custom-sources/pbs-sources.list
    local -r  custom_pve=./custom-sources/pve-sources.list

    #Check for APT sources file
    if test -f "${sources}"; then
    	echo "${sources} exists"
        rm --recursive --force --verbose ${sources}
    else
        echo "${sources} does not exist"
    fi

    if ${IS_PBS}; then
    	echo "Proxmox Backup Server detected"
        cp ${custom_pbs} /etc/apt/
        mv /etc/apt/pbs-sources.list /etc/apt/sources.list 
    elif ${IS_PVE}; then
    	echo "Proxmox Virtual Environment detected"
        cp ${custom_pve} /etc/apt/
        mv /etc/apt/pve-sources.list /etc/apt/sources.list
    else 
        printf "####\n## Unable to determine Proxmox installation type\n####\n" 
    fi
}

function disable-subscription-message(){
	sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	systemctl restart pveproxy.service
}

function setup-fail2ban(){

    apt update
    apt install fail2ban -y
    cp ./fail2ban-files/defaults-debian.conf /etc/fail2ban/jail.d/defaults-debian.conf
    cp ./fail2ban-files/pve-web-auth.conf /etc/fail2ban/jail.d/
    cp ./fail2ban-files/pve-web-auth-filter.conf /etc/fail2ban/filter.d/

    if ${IS_PBS}; then
        echo "PBS detected"
    
        cp ./fail2ban-files/defaults-debian.conf /etc/fail2ban/jail.d/defaults-debian.conf
        cp ./fail2ban-files/pbs-web-auth.conf /etc/fail2ban/jail.d/
        cp ./fail2ban-files/pbs-web-auth-filter.conf /etc/fail2ban/filter.d/

        # Test regex evaluation
        fail2ban-regex /var/log/daemon.log /etc/fail2ban/filter.d/pbs-web-auth-filter.conf

        # Check jail status
        systemctl restart fail2ban
        fail2ban-client status pbs-web-auth
    
    elif ${IS_PVE}; then
        echo "PVE detected"
        cp ./fail2ban-files/defaults-debian.conf /etc/fail2ban/jail.d/defaults-debian.conf
        cp ./fail2ban-files/pve-web-auth.conf /etc/fail2ban/jail.d/
        cp ./fail2ban-files/pve-web-auth-filter.conf /etc/fail2ban/filter.d/

        # Test regex evaluation
        fail2ban-regex /var/log/daemon.log /etc/fail2ban/filter.d/pve-web-auth-filter.conf

        # Check jail status
        systemctl restart fail2ban
        fail2ban-client status pve-web-auth
    else
        printf "####\n## Unable to determine Proxmox installation type\n####\n"
    fi
}

detect-version
configure-sources
setup-fail2ban
disable-subscription-message

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR
