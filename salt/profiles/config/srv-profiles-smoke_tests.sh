#!/bin/bash
set -e
. /opt/smoke.sh/smoke.sh

cd /home/{{ pillar.elife.deploy_user.username }}/profiles
# TODO: needs new version of self-reliant smoke tests that do not require parameters
#docker-compose exec wsgi ./smoke_tests_wsgi.sh

set +e
smoke_url_ok localhost/ping
smoke_url_ok localhost/profiles
smoke_report

