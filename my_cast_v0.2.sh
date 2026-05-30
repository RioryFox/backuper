#!/bin/sh
set -e
clear

open_file=true
SCRIPT_DIR="$(pwd)"

git_push_force() {
    if result=$(git push "$1" main --force 2>&1); then
        echo "✓ $1 push successful"
    else
        echo "✗ $1 push failed: $result"
    fi
} 

get_json_value() {
    local file="$1"
    local key="$2"
    if [ -f "$file" ] && command -v jq >/dev/null 2>&1; then
        jq -r "$key" "$file"
    else
        echo "ERROR: $file not found or jq missing" >&2
        return 1
    fi
}

while getopts ":flu" opt; do
	case ${opt} in
    		f)
			open_file=false
		;;
    		l)
			set +e
			git add .
			if git diff --cached --quiet; then
    				echo "No changes to commit, skipping Git push"
			else
				git commit -m "Load from $(hostname) on $(date '+%Y-%m-%d %H:%M:%S')"
				git_push_force origingit 
				git_push_force origintea
				git_push_force origincode
			fi
			while true; do
				read -p "Script loaded to git suc, contionue?(Y/N)" CHOISE
				CHOISE=$(echo "$CHOISE" | tr '[:lower:]' '[:upper:]')
				case ${CHOISE} in
					Y|YES|YEA|YEAH|OFCORSE) 
						break
					;;
					N|NO|NOPE|NEVER) 
						exit 1
					;;
					*)
						echo "Invalid answear..." 
					;;
				esac
			done
			set -e
		;;

		u)
			echo "Self-update initiated..."
			SCRIPT_PATH="$(realpath "$0")"
			TMP_DIR=$(mktemp -d)
		    	git clone --depth 1 https://github.com/RioryFox/backuper.git "$TMP_DIR"
		    	NEW_SCRIPT=$(find "$TMP_DIR" -maxdepth 1 -name "my_cast*.sh" -type f | head -1)
		
		    	if [ -n "$NEW_SCRIPT" ]; then
				(
					sleep 1.5
					cp "$NEW_SCRIPT" "$SCRIPT_PATH"
					chmod +x "$SCRIPT_PATH"
					rm -rf "$TMP_DIR"
					echo "Update complete. Script is now up to date."
			        ) & echo "Update applied. Please re-run the script manually."
				exit 0
			else
		        	echo "No script found in repository"
		        	rm -rf "$TMP_DIR"
		        	exit 1
		    	fi
		;; 

    		\\?)
			echo "Unknown option provided: -${OPTARG}"
      			exit 1
      		;;
  	esac
done

if [ "$open_file" = true ]; then
  echo "                  OPEN FILE..."
  sudo nano /etc/nixos/configuration.nix
else
  echo "Skipping file opening because of the -f flag."
fi

for DEVICE in $(lsblk -d -o NAME,RM,TYPE -n | awk '$2=="1" && $3=="disk" {print "/dev/"$1}'); do
	if [ ! -b "${DEVICE}1" ] && [ ! -b "${DEVICE}p1" ]; then
    		echo "No partition on $DEVICE, skipping..."
    		continue
	fi
	if [ -z "$DEVICE" ]; then
		echo "NO SD OR FLASH CARD!!!"
        	echo "Don't forget to create marker: touch \"$MOUNT_POINT/.fbi_backup_disk\""
		exit 1
	else
		MOUNT_POINT=$(findmnt -n -o TARGET --source "${DEVICE}1" )
		if [ -f "$MOUNT_POINT/.fbi_backup_disk" ]; then
	    		break
		fi
	fi
done

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
	set +e
    	git_push_force origintea
   	git_push_force origingit
	git_push_force origincode
	set -e
else
 	echo "No changes in /etc"
fi

cd - > /dev/null
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
