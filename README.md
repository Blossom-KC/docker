# Blossom Docker Deployment (v8.3)

A docker compose deployment for running Blossom Platform application with all configurations are already set.

- This repository does not contain the application code, only infrastructure configurations.*
- This repository does not configure the MySQL 8.0.* database, and assume you'll be using RDS or install it manually.*

### how to use this:
1. install docker and docker-compose on host and make sure they start on boot.
2. clone this repository or download its files to /root/blossom-docker.
3. on the host, create `/var/www` and `/var/www/html` directories.
4. extract all files from the application zip file to `/var/www/html`.
5. copy the content of `cron/www` to `/var/www`.
6. set owner of `/var/www` to www-data using this command: `sudo chown -R 82:82 /var/www`.
7. run `docker-compose up -d` to start the containers.

### after install:
- now the system is up and running, you can access the application on `http://server:80` and setup db connection. 
- Usually you would want to use some kind of reverse proxy that would handle SSL termination and forward requests to the application.
