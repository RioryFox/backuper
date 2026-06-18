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

    echo "Поиск хранилища с маркером '.fbi_backup_disk'..."

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
            echo "Найдено хранилище: $DEVICE смонтирована в $MOUNT_POINT"
            break
        fi
    done

    if [ -z "$DEVICE" ]; then
        echo "ОШИБКА: Не найдено хранилище с маркером '.fbi_backup_disk'"
        echo "Создайте маркер: touch '/run/media/.../.fbi_backup_disk'"
        return 1
    fi

    local BACKUP_DIR="$MOUNT_POINT/backups"
    mkdir -p "$BACKUP_DIR" 2>/dev/null || sudo mkdir -p "$BACKUP_DIR"

    echo "Создание резервной копии $SOURCE_PATH в $BACKUP_DIR..."

    local RSYNC_DEST="$BACKUP_DIR/$(basename "$SOURCE_PATH")"
    rsync -azq --checksum --delete "$SOURCE_PATH/" "$RSYNC_DEST/" --exclude='containers/storage/overlay*' --exclude='*.sock' --exclude='*.pid' 2>/dev/null
    echo "Команда rsync выполнена..."
    local DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)
    local ARCHIVE_NAME="${BACKUP_NAME}_${DATE_SUFFIX}.tar.gz"
    sudo tar -czpf "$BACKUP_DIR/$ARCHIVE_NAME" -C / "$(realpath "$SOURCE_PATH" --relative-to=/)" 2>/dev/null

    sudo find "$BACKUP_DIR" -name "${BACKUP_NAME}_*.tar.gz" -type f 2>/dev/null | sort | head -n -10 | xargs -r sudo rm -f

    echo "Полный бэкап раздела завершён: $BACKUP_DIR/$ARCHIVE_NAME"
    return 0
}


upload_to_yadisk() {

    local FILE="$1"    local TOKEN="$YADISK_TOKEN"
    local YOUR_YAAPP="$YAPP"

    if [ -z "$TOKEN" ]; then
        echo " YADISK_TOKEN не задан, пропускаем"
        return 1
    fi

    local FILENAME=$(basename "$FILE")
    echo "Загружаем $FILENAME на Яндекс.Диск..."

    local UPLOAD_URL=$(curl -s -H "Authorization: OAuth $TOKEN" \
        "https://cloud-api.yandex.net/v1/disk/resources/upload/?path=app:/$YOUR_YAAPP" | jq -r '.href')

    if [ -z "$UPLOAD_URL" ] || [ "$UPLOAD_URL" = "null" ]; then
        echo "Не удалось получить ссылку для загрузки"
        return 1
    fi

    curl -s -T "$FILE" "$UPLOAD_URL"
    echo "Загружено: https://disk.yandex.ru/app/$YOUR_YAAPP/$FILENAME"
}
