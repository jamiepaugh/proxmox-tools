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
    local -r  custom_pbs=/root/pve-tools/custom-sources/pbs-sources.list
    local -r  custom_pve=/root/pve-tools/custom-sources/pve-sources.list

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

function configure-placeholder-subscription() {

    local -r placeholder_subscription_url=https://github.com/Jamesits/pve-fake-subscription/releases/download/v0.0.7/pve-fake-subscription_0.0.7_all.deb
    
    wget ${placeholder_subscription_url}
    dpkg -i pve-fake-subscription_0.0.7_all.deb
    echo "127.0.0.1 shop.maurer-it.com" | tee -a /etc/hosts
    rm pve-fake-subscription_0.0.7_all.deb

}

detect-version
configure-sources
configure-placeholder-subscription

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR