#!/bin/sh


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
