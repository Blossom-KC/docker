#host_instance=$HOST_HOSTNAME
#name=$(cat /var/www/cron_instance)
#if [ "$host_instance" != "$name" ]
# then
#    exit
#fi

date > /var/www/minute.log
php /var/www/html/cron_jobs/_send_emails.php
