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

### ARM machines

Before starting the containers on ARM, copy `.env.example` to `.env` (or edit
your existing `.env`) and set:

```dotenv
IXED_LOADER=ixed.8.3-arm.lin
```

This selects the ARM loader for both PHP-FPM and cron. The default is
`ixed.8.3.lin` for x86-64. Both loaders mount at the same container path, so
`php.ini` needs no changes. Apply a change with `docker compose up -d`.

### after install:
- now the system is up and running, you can access the application on `http://server:80` and setup db connection. 
- Usually you would want to use some kind of reverse proxy that would handle SSL termination and forward requests to the application.

### Let's Encrypt with Apache mod_md

Apache can obtain and renew its own certificates without Certbot or another
container. The default Compose configuration continues to serve HTTP; enable
managed HTTPS through `.env` as described below.

1. Point your public hostname's DNS records (including AAAA if present) to this
   server. Allow inbound TCP port 443 and outbound HTTPS. This configuration uses
   TLS-ALPN-01 validation (`acme-tls/1`) on port 443 and supports a single hostname,
   not wildcards. TLS connections must reach Apache directly or through a TCP
   passthrough proxy; an upstream proxy that terminates TLS prevents this challenge
   from reaching Apache.
2. Copy `.env.example` to `.env`, set `APACHE_VHOST=vhost-letsencrypt.conf`,
   and set `LE_DOMAIN` to the hostname only (no scheme
   or path) and `LE_EMAIL` to your contact email. Enabling this configuration accepts
   [Let's Encrypt's terms of service](https://letsencrypt.org/repository/).
3. Validate and start the deployment:

   ```sh
   docker compose config --quiet
   docker compose up -d
   docker compose logs -f blossom-apache
   ```

No additional Compose file is needed. Without `.env`, or with
`APACHE_VHOST=vhost.conf`, Apache serves HTTP without the renewal monitor.
Do not also enable the manual `vhost-ssl.conf` mount when using managed HTTPS.
Selecting `vhost-letsencrypt.conf` replaces the HTTP-only virtual host,
keeps the same PHP-FPM backend and validates certificates entirely over HTTPS.
Port 80 may remain closed in your firewall. The base Compose file still publishes
`80:80` for optional HTTP-to-HTTPS redirects; remove that mapping from
`docker-compose.yml` if you also want to stop publishing HTTP. Redirects are only
available when port 80 is reachable. HTTPS may initially return 503 or use a temporary untrusted certificate
until issuance completes. The notification monitor activates new certificates
with a graceful reload within 30 seconds and retries failed configuration checks.

Certificates, account keys, and renewal state persist in `./apache-md/`, beside
`docker-compose.yml`, mounted at `/usr/local/apache2/md` in Apache. Docker creates
the folder if needed. A `.gitkeep` preserves the folder in Git; all generated
contents are ignored because they include private keys.
Back up the folder securely and preserve its ownership and permissions; Apache
manages the permissions of its contents. Apache's [mod_md](https://httpd.apache.org/docs/2.4/mod/mod_md.html)
handles issuance and renewal; no host cron job is required.

If upgrading from the previous named-volume configuration, copy existing state
before recreating Apache. On the Linux deployment host, from the Compose directory,
run these commands with permission to preserve file ownership (usually as root):

```sh
docker compose stop blossom-apache
mkdir -p apache-md
chmod 700 apache-md
docker cp -a "$(docker compose ps -aq blossom-apache):/usr/local/apache2/md/." ./apache-md/
docker compose up -d blossom-apache
```

Use a destination containing only `.gitkeep` (or an empty folder) for this migration.
Keep the old named volume as a
backup until HTTPS is verified; changing the mount does not copy its data
automatically.

For testing, use a separate deployment directory with its own `.env` and
`apache-md/` folder, uncomment the staging `LE_CA`, and use `-p blossom-staging`
with Compose to isolate the containers. A different project name alone does not
isolate bind-mounted certificate storage. Staging certificates are untrusted.
Stop that deployment before starting production on the same ports. Check Apache's
logs for validation errors if issuance does not complete.

Run `sh tests/mod-md.sh` to test the reload monitor without Docker or ACME requests.
