#!/bin/sh
set -eu

reload_marker=/usr/local/apache2/md/staging/reload-required

# mod_md invokes this as www-data only after a certificate is ready. Its
# staging directory is writable by that user; the root monitor reloads httpd.
if [ "${1:-}" = notify ]; then
    touch "$reload_marker"
    exit 0
fi

# Other virtual hosts use Apache's normal startup without a renewal monitor.
if [ "${APACHE_VHOST:-vhost.conf}" != vhost-letsencrypt.conf ]; then
    exec httpd-foreground
fi

: "${LE_DOMAIN:?Set LE_DOMAIN to your public hostname}"
: "${LE_EMAIL:?Set LE_EMAIL to your contact email}"

httpd -t
apache_pid=$$
(
    while kill -0 "$apache_pid" 2>/dev/null; do
        sleep 30
        if [ -f "$reload_marker" ]; then
            # Claim the notification before reloading so a later notification
            # remains pending. Preserve it on validation or signal failure.
            mv "$reload_marker" "$reload_marker.pending"
        fi
        if [ -f "$reload_marker.pending" ]; then
            if httpd -t && kill -USR1 "$apache_pid"; then
                rm -f "$reload_marker.pending"
            else
                echo 'mod_md: certificate reload failed; retrying in 30 seconds' >&2
            fi
        fi
    done
) &

# Keep Apache as PID 1 for normal Docker stop/restart signal handling.
exec httpd-foreground
