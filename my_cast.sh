#!/bin/sh
set -e
clear

open_file=true

while getopts ":f" opt; do
  case ${opt} in
    f)
      open_file=false
      shift
      ;;
    \\?)
      echo "Unknown option provided: -${OPTARG}"
      exit 1
      ;;
  esac
done

if [ "$open_file" = true ]; then
  echo "                  OPEN FILE..."
  sleep 0.35
  sudo nano /etc/nixos/configuration.nix
else
  echo "Skipping file opening because of the -f flag."
fi

DEVICE=$(lsblk -o NAME,RM -n | awk '$2=="1" {print "/dev/"$1; exit 1}')

if [ -z "$DEVICE" ]; then
	echo "NO SD CARD!!!"
        exit 1
else
	MOUNT_POINT=$(findmnt -n -o TARGET --source "${DEVICE}1" )
	if [ ! -f "$MOUNT_POINT/.fbi_backup_disk" ]; then
	    echo "ERROR: $MOUNT_POINT does not contain .fbi_backup_disk marker file!"
	    echo " This doesn't look like your backup SD card."
	    echo " Create marker: touch \"$MOUNT_POINT/.fbi_backup_disk\""
	    exit 1
	fi
	echo "creating new copy in $MOUNT_POINT..."
	rsync -avzq --checksum --delete /etc/ "$MOUNT_POINT/etc/"
	BACKUP_NAME="etc_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
	sudo tar -czpf "$MOUNT_POINT/$BACKUP_NAME" -C / etc
	sudo find "$MOUNT_POINT" -name "etc_backup_*.tar.gz" -type f | sort | head -n -10 | xargs -r sudo rm -f
	echo "pushing git changes..."
	cd /etc
	git add .
	if ! git diff --cached --quiet; then
    		git commit -m "Auto backup from $(hostname) on $(date '+%Y-%m-%d %H:%M:%S')"
    		git push gitea main #2>&1 | grep -v "seahorse-Message"
    		echo "Git backup pushed to Gitea"
		if git remote get-url origin >/dev/null 2>&1; then
#        		git push origin main #2>&1 | grep -v "seahorse-Message"
        		echo "Git backup pushed to GitHub"
    		else
        		echo "Remote 'origin' not configured, skipping GitHub"
    		fi
	else
    		echo "No changes in /etc"
	fi

	cd - > /dev/null
fi
sleep 1
echo "			UPDATING CHANNELS..."
sudo nix-channel --update > /dev/null 
echo "			REBUILDING NIXOS..."
sudo nixos-rebuild switch > /dev/null
echo ""
echo "			DELITING CACHE DATA..."
sudo nix-collect-garbage -d > /dev/null  2>&1

clear
fastfetch 
ipfetch
#oneko
