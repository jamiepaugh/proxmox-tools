#!/bin/bash

function detect-version() {

	pveversion
	if [$? -eq 0]; then
		echo "pveversion ran succesfully\n"
	else
		echo "pveversion did not run\n"
	fi

}

detect-version

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR