#host_instance=$HOST_HOSTNAME
#name=$(cat /var/www/cron_instance)
#if [ "$host_instance" != "$name" ]
# then
#    exit
#fi

date > /var/www/night.log
php /var/www/html/cron_jobs/_reminders_sender.php
