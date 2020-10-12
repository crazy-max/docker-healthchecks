#!/usr/bin/with-contenv sh

mkdir -p /etc/services.d/healthchecks
cat > /etc/services.d/healthchecks/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
uwsgi --ini /opt/healthchecks/uwsgi.ini
EOL
chmod +x /etc/services.d/healthchecks/run
