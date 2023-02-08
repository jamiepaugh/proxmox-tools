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

detect-version
configure-sources

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR
