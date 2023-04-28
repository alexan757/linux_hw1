#!/bin/bash
#записываем локации для резервного копирования в переменную CONFIGFILES, создаем архив и переносим его в папку /user_backups
CONFIGFILES="/etc/ssh /etc/xrdp /etc/vsftpd.conf /var/log /home"
sudo tar cvf /tmp/full-backup "created on `date '+%d-%B-%Y'`.tar" --exclude=".*" $CONFIGFILES
sudo mv /tmp/full-backup "created on `date '+%d-%B-%Y'`.tar" /user_backups/