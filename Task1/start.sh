#!/bin/bash

#1.Проверка на наличие репозитория Backports в списке репозиториев. Если отсутствует — добавляем
if ! grep -q "backports" /etc/apt/sources.list;
then echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list

fi

#2.Обновление пакетного менеджера
sudo apt update -y && sudo apt upgrade -y

#3.Установка и запуск Apache2
sudo apt install apache2 ssl-cert -y
sudo systemctl enable apache2
sudo systemctl start apache2

#4.Установка Python
sudo apt install -y python3

#5.Установка, поднятие SSH-сервера и замена ключей по умолчанию
sudo apt install -y openssh-server && sudo systemctl restart ssh && sudo systemctl enable ssh
sudo mkdir /etc/ssh/default_keys && sudo mv /etc/ssh/ssh_host_* /etc/ssh/default_keys
sudo dpkg-reconfigure openssh-server && sudo systemctl restart ssh

#6.Автоматическая очистка кэша
days="$1"
#установить значения по умолчанию в днях. Если аргумент не назчанен, то по умолчанию берется 7 дней
if [ -z "$days" ]; then
  days=7
fi

find ~/.cache -depth -type f -mtime +"$days" -delete

#7.Проверка ПО на определенных портах
if [ $# -ne 1 ]; then
        echo "Usage: program_on_port.sh [port]"
        echo "       [port] - a port to check"
        echo "Example: ./program_on_port.sh 8001"
        exit 1
    fi

    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]]; then
        echo "Error: $1 is not an integer"
        exit 1
    fi

    lsof -i tcp:"$1"


main "$@"

#8.Создание бэкап файла заданных директорий
validate_config_file() {
    source "$1"

    if [ -z "${BACKUP_DIR}" ]; then
        echo "BACKUP_DIR is not set"
        exit 1
    fi

    if [ -z "${SOURCE_DIR}" ]; then
        echo "SOURCE_DIR is not set"
        exit 1
    fi

    if [ -z "${EXCLUDE_DIRS}" ]; then
        echo "EXCLUDE_DIRS is not set"
        exit 1
    fi

    if [ -z "${EXCLUDE_FILES}" ]; then
        echo "EXCLUDE_FILES is not set"
        exit 1
    fi

    if [ -z "${EXCLUDE_EXTENSIONS}" ]; then
        echo "EXCLUDE_EXTENSIONS is not set"
        exit 1
    fi

    if [ -z "${WITH_COMPRESSION}" ]; then
        echo "WITH_COMPRESSION is not set"
        exit 1
    fi

    if [ -z "${WITH_ENCRYPTION}" ]; then
        echo "WITH_ENCRYPTION is not set"
        exit 1
    fi

    if [ -z "${GPG_PASSPHRASE}" ]; then
        echo "GPG_PASSPHRASE is not set"
        exit 1
    fi

    echo "Validation complete"
}

create_config_file() {
    echo "Creating a defualt config file at: $1"

    echo "BACKUP_DIR=path/to/backup/dir" > "$1"
    echo "SOURCE_DIR=path/to/source/dir" >> "$1"
    echo "EXCLUDE_DIRS=0" >> "$1"
    echo "EXCLUDE_FILES=0" >> "$1"
    echo "EXCLUDE_EXTENSIONS=0" >> "$1"
    echo "WITH_COMPRESSION=true" >> "$1"
    echo "WITH_ENCRYPTION=true" >> "$1"
    echo "GPG_PASSPHRASE=passphrase" >> "$1"

    echo "Config file created"
}

create_backup() {#!/usr/bin/env bash
    echo "Creating backup"

    if [ ! -d "${BACKUP_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
    fi

    if [ ! -d "${SOURCE_DIR}" ]; then
        echo "Source directory does not exist"
        exit 1
    fi

    # копирование всех файлов и папок из источника
    rsync -av --exclude-from="${EXCLUDE_DIRS}" --exclude-from="${EXCLUDE_FILES}" --exclude-from="${EXCLUDE_EXTENSIONS}" "${SOURCE_DIR}" "${BACKUP_DIR}"

    if [ "${WITH_COMPRESSION}" == "true" ]; then
        echo "Compressing backup"
        tar -czf "../${BACKUP_DIR}/backup.tar.gz" "${BACKUP_DIR}"
        echo "Compression complete"

        if [ "${WITH_ENCRYPTION}" == "true" ]; then
            echo "Encrypting backup"
            gpg --batch --yes --passphrase="${GPG_PASSPHRASE}" --symmetric "../${BACKUP_DIR}/backup.tar.gz"
            echo "Encryption complete"
        fi
        # удаление несжатой копии
        rm -rf "${BACKUP_DIR}"
    fi

    echo "Backup created"
}

main() {

    if [ $# -eq 0 ]; then
        default_config_file="config.sh"
        create_config_file $default_config_file
        echo "Fill the config file with the desired values and run the script again."
        exit 1
    fi

    if [ -f "$1" ]; then
        echo "Using config file: $1"
        validate_config_file "$1"
        create_backup "$1"
    else
        echo "Config file not found: $1"
        exit 1
    fi

}

main "$@"

#9.Создание пользователей

USER=$1 # базовая часть имени пользователя
PASS=$2 # базовая часть пароля
N=$3    # количество пользователей
for (( i = 1; i <= $N; i++ )); do
  useradd "${USER}_$i" && $(echo "${USER}_$i:${PASS}_$i" |chpasswd)
  echo "User ${USER}_$i added!"
done

#10.Генератор случаных паролей заданной длины

main() {
    if [ $# -ne 1 ]; then
        echo "Usage: random_password.sh [n]"
        echo "       [n] - the length of the requested password"
        echo "Example: ./random_password.sh 15"
        exit 1
    fi

    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]]; then
        echo "Error: $1 is not an integer"
        exit 1
    fi

    password=$(strings /dev/urandom | grep -o '[[:alnum:]]' | head -n "$1" | tr -d '\n')
    echo "$password"

}

main "$@"
