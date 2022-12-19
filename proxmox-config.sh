#!/bin/bash

function detect-version() {

	pveversion
	if [$? -eq 0]; then
		echo "pveversion ran succesfully"
	else
		echo "pveversion did not run"
	fi

	proxmox-backup-client
	if [$? -eq 0]; then
		echo "proxmox-backup-client ran succesfully"
	else
		echo "proxmox-backup-client did not run"
	fi

}

detect-version

finish() {
  result=$?
    printf "proxmox-enterprise-config.sh completed succesfully\n Please reboot your system to complete configuration\n"
  exit ${result}
}
trap finish EXIT ERR