#!/bin/sh


#TODO: 
#- create json-database to git and backups and flakes/updates configs
#- Sleep it is 8 day whan i get sleep at 3:02... 


set -e
clear

YADISK_TOKEN=""
open_file=true
rebooter=false
poweroffer=false
clearer=false
SCRIPT_DIR="$(pwd)"
source "$SCRIPT_DIR/lib/backup.sh"
source "$SCRIPT_DIR/lib/git.sh"

#---Functions 

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

#А ВОТ С ЭТИМ ЩА БУДУРАБОТАТЬ
check_space(){
	DATA_SIZE=$(du -sm "$1" | cut -fi)
	if check_disk_space "$2" "$DATA_SIZE" 64; then
		return 1
	fi
	return 0 
}

#---Основная часть скрита

while getopts ":flurpc" opt; do
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

		r)
			rebooter=true
		;;  	

		p)
			poweroffer=true
		;;
		c)
			clearer=true
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

#---Локальное Архивирование

backup_to_sd '/home/homefox/Documents' 'home_backup'
#---Онлайн копия

echo "pushing git changes..."
cd /home/homefox/Documents/HF01MS-16
git add .
if ! git diff --cached --quiet; then
 	git commit -m "Auto backup from $(hostname) on $(date '+%Y-%m-%d %H:%M:%S')"
	set +e
    git_push_force origintea
   	git_push_force origingit
	git_push_force origincode
	set -e
else
 	echo "No changes in " & pwd
fi

#---Перестройка системы

cd - > /dev/null
echo "			UPDATING CHANNELS..."
sudo nix-channel --update > /dev/null; sudo nix --extra-experimental-features "nix-command flakes" flake update > /dev/null
echo "			REBUILDING NIXOS..."
sudo nixos-rebuild switch --upgrade --flake ../  > /dev/null
echo ""

if [clearer]; then
	echo "			DELITING CACHE DATA..."
	sudo nix-collect-garbage -d > /dev/null  2>&1

#---Очистка и вывод полезной информации

clear
fastfetch 
#ipfetch

if [ "$rebooter" = true ]; then
	echo "system will be roboot because of -r flag in 5 seconds..."
	sleep 5
	reboot
elif [ "$poweroffer" = true ]; then
	echo "system will be shotdown because of -p flag in 5 seconds..."
	sleep 5
	poweroff
fi
#oneko
