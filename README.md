# 🦊 FBI Backup System

**Скрипт автоматического резервного копирования для NixOS**

## 📋 Описание

Скрипт `my_cast.sh` выполняет полное резервное копирование каталога `/etc` на SD-карту (или USB-флешку) с последующей синхронизацией в Git-репозитории (локальный Gitea + GitHub).

### Что делает скрипт:

| Действие | Описание |
|----------|----------|
| 🔍 Поиск съёмного носителя | Автоматически находит внешний носитель с маркером `.fbi_backup_disk` |
| 💾 Бэкап `/etc` | Создаёт архив `etc_backup_YYYYMMDD_HHMMSS.tar.gz` |
| 🔄 Синхронизация | Копирует актуальную версию `/etc` через `rsync` |
| 🗑️ Ротация | Оставляет только последние 10 архивов |
| 📦 Git-коммит | Фиксирует изменения в локальном репозитории |
| ☁️ Push | Отправляет изменения на Gitea и GitHub |
| 🔧 NixOS | Обновляет каналы и пересобирает систему |

---

## 🚀 Установка

###Я пока не очень умею работать с .md форматом

### 1. Клонирование репозитория

```bash
git clone https://github.com/*Имя аккаунта*/*имя репозитория*.git /*ваш путь*/backuper
cd /*ваш путь*/backuper

### 2. Установка прав

chmod +x my_cast.sh
sudo ln -sf /opt/backuper/my_cast.sh /usr/local/bin/fbi-backup

### 3. Создание маркера

# Создаём метку для идентификации диска
touch /run/media/homefox/*ваше устройство*/.fbi_backup_disk

### 4. Создание резервных репозиториев

cd /etc
git remote add gitea http://localhost:3001/RioryFox/nixos_server.git
git remote add origin https://github.com/RioryFox/nixos_server.git

---

## Восстановление из бэкапа 

### Из папки

sudo rsync -av /run/media/homefox/*ваше устройство*/etc/ /etc
 
### Из архива

sudo tar -xzvpf /run/media/homefox/FBI_SD01/etc_backup_*ваш файл*.tar.gz -C /
