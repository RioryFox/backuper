#!/bin/sh

#TODO: 
#- create json-database to git and backups and flakes/updates configs
#- Sleep it is 8 day whan i get sleep at 3:02... 

set -e
clear

open_file=true
rebooter=false
SCRIPT_DIR="$(pwd)"

#---Functions

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

backup_to_sd() {
    local SOURCE_PATH="$1"
    local BACKUP_NAME="${2:-$(basename "$SOURCE_PATH")_backup}"
    local MOUNT_POINT=""
    local DEVICE=""

    if [ -z "$SOURCE_PATH" ]; then
        echo "Ошибка: не указан путь для бэкапа"
        echo "Использование: backup_to_sd <путь> [имя_бэкапа]"
        return 1
    fi

    if [ ! -d "$SOURCE_PATH" ]; then
        echo "Ошибка: путь $SOURCE_PATH не существует"
        return 1
    fi

    echo "Поиск SD-карты с маркером '.fbi_backup_disk'..."

    for DEV in $(lsblk -d -o NAME,RM,TYPE -n | awk '$3=="disk" {print "/dev/"$1}'); do
        if [ -b "${DEV}1" ]; then
            PARTITION="${DEV}1"
        elif [ -b "${DEV}p1" ]; then
            PARTITION="${DEV}p1"
        else
            echo "Нет раздела на $DEV, пропускаем..."
            continue
        fi

        local MNT=$(findmnt -n -o TARGET --source "$PARTITION" 2>/dev/null || true)

        if [ -z "$MNT" ]; then
            echo "$PARTITION не смонтирован, пропускаем..."
            continue
        fi

        if [ -f "$MNT/.fbi_backup_disk" ]; then
            DEVICE="$DEV"
            MOUNT_POINT="$MNT"
            echo "Найдена SD-карта: $DEVICE смонтирована в $MOUNT_POINT"
            break
        fi
    done

    if [ -z "$DEVICE" ]; then
        echo "ОШИБКА: Не найдена SD-карта с маркером '.fbi_backup_disk'"
        echo "Создайте маркер: touch '/run/media/.../.fbi_backup_disk'"
        return 1
    fi

    local BACKUP_DIR="$MOUNT_POINT/backups"
    mkdir -p "$BACKUP_DIR" 2>/dev/null || sudo mkdir -p "$BACKUP_DIR"

    echo "Создание резервной копии $SOURCE_PATH в $BACKUP_DIR..."

    local RSYNC_DEST="$BACKUP_DIR/$(basename "$SOURCE_PATH")"
    rsync -avzq --checksum --delete "$SOURCE_PATH/" "$RSYNC_DEST/"
    echo "Команда rsync выполнена..."
    local DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)
    local ARCHIVE_NAME="${BACKUP_NAME}_${DATE_SUFFIX}.tar.gz"
    sudo tar -czpf "$BACKUP_DIR/$ARCHIVE_NAME" -C / "$(realpath "$SOURCE_PATH" --relative-to=/)" 2>/dev/null

    sudo find "$BACKUP_DIR" -name "${BACKUP_NAME}_*.tar.gz" -type f 2>/dev/null | sort | head -n -10 | xargs -r sudo rm -f

    echo "Полный бэкап раздела завершён: $BACKUP_DIR/$ARCHIVE_NAME"
    return 0
}

check_space(){
	DATA_SIZE=$(du -sm "$1" | cut -fi)
	if check_disk_space "$2" "$DATA_SIZE" 64; then
		return 1
	fi
	return 0 
}

#---Основная часть скрита

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

		r)
			rebooter=true;
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

backup_to_sd '/etc' 'etc_backup'
backup_to_sd '/var/lib' 'var-lib_backup'
#backup_to_sd '/home' 'home_backup'

#---Онлайн копия

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

#---Перестройка системы

cd - > /dev/null
echo "			UPDATING CHANNELS..."
sudo nix-channel --update > /dev/null 
echo "			REBUILDING NIXOS..."
sudo nixos-rebuild switch > /dev/null
echo ""
echo "			DELITING CACHE DATA..."
sudo nix-collect-garbage -d > /dev/null  2>&1

#---Очистка и вывод полезной информации

clear
fastfetch 
ipfetch

if rebooter; then
	echo "system will be roboot because of -r flag in 5 seconds..."
	sleep 5
	reboot
fi
#oneko
