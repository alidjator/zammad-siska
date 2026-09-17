#!/usr/bin/env bash
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
#
# Creates the local Mailpit SMTP sink container used by
# script/toggle_smtp_sink.rb (mitigation #2 for the email-notification
# leak found in testing -- see docs/TASKLIST_SISKA.md /
# ACTIVITY_LOG_SISKA.md "Investigasi Notifikasi Email Selama Pengujian").
#
# Joins the same docker network as the Zammad containers so the app can
# reach it by container name alone (no host port needed for SMTP) --
# only the web UI (to inspect captured test mail) is published, and only
# to localhost, since it renders whatever content was captured.
#
# Idempotent: safe to re-run, does nothing if the container already
# exists (running or stopped -- start it manually with
# `docker start siska-qa-mailsink` if stopped).
#
#   bash script/create_smtp_sink.sh

set -euo pipefail

CONTAINER_NAME='siska-qa-mailsink'
NETWORK='zammad-staging_default'

if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Container $CONTAINER_NAME already exists -- skipping create."
  exit 0
fi

docker run -d \
  --name "$CONTAINER_NAME" \
  --network "$NETWORK" \
  -p 127.0.0.1:8025:8025 \
  --restart unless-stopped \
  axllent/mailpit:latest

echo "Created $CONTAINER_NAME on network $NETWORK."
echo "Captured test mail viewable at http://127.0.0.1:8025 (localhost only)."
