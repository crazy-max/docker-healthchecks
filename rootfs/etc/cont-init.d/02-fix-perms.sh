#!/usr/bin/with-contenv sh

echo "Fixing perms..."
mkdir -p /data/img
chown -R healthchecks. \
  /data \
  /opt/healthchecks
