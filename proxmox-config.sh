#!/bin/bash

function detect-version() {

	if [pveversion]; then
		echo "pveversion ran succesfully"
	else
		echo "pveversion did not run"
	fi

}

detect-version

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR