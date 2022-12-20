#!/bin/bash
set -e
. /opt/smoke.sh/smoke.sh

cd /home/{{ pillar.elife.deploy_user.username }}/profiles

set +e
smoke_url_ok localhost/ping

sleep 5

smoke_url_ok localhost/profiles
smoke_report

