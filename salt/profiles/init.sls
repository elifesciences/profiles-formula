profiles-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/profiles.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/profiles/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - fetch_pull_requests: True

    file.directory:
        - name: /srv/profiles
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: profiles-repository

profiles-logs:
    file.directory:
        - name: /srv/profiles/var/logs/
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - dir_mode: 775
        - file_mode: 664
        - recurse:
            - user
            - group
        - require:
            - profiles-repository

    # the g+s flag makes sure that new files and directories 
    # created inside have the www-data group
    cmd.run:
        - name: chmod -R g+s /srv/profiles/var/logs
        - require:
            - file: profiles-repository

profiles-app-config:
    file.managed:
        - name: /srv/profiles/app.cfg
        - source: salt://profiles/config/srv-profiles-app.cfg
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require: 
            - profiles-repository
            - profiles-logs

profiles-clients-config:
    file.managed:
        - name: /srv/profiles/clients.yaml
        - source: salt://profiles/config/srv-profiles-clients.yaml
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-repository

profiles-install:
    cmd.run:
        - name: ./install.sh
        - cwd: /srv/profiles/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-repository
            - profiles-app-config
            - profiles-clients-config
            - profiles-db
            - profiles-db-possible-cleanup

profiles-uwsgi-config:
    file.managed:
        - name: /srv/profiles/uwsgi.ini
        - source: salt://profiles/config/srv-profiles-uwsgi.ini
        - template: jinja
        - require:
            - profiles-repository

profiles-uwsgi-upstart:
    file.managed:
        - name: /etc/init/uwsgi-profiles.conf
        - source: salt://profiles/config/etc-init-uwsgi-profiles.conf
        - template: jinja

profiles-uwsgi-systemd:
    file.managed:
        - name: /lib/systemd/system/uwsgi-profiles.service
        - source: salt://profiles/config/lib-systemd-system-uwsgi-profiles.service
        - template: jinja

profiles-uwsgi-service:
    cmd.run:
        - name: service uwsgi-profiles restart
        - require:
            - profiles-uwsgi-upstart
            - profiles-uwsgi-systemd
            - profiles-app-config
            - profiles-clients-config
            - profiles-install
            - profiles-uwsgi-config

profiles-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/profiles.conf
        - source: salt://profiles/config/etc-nginx-sites-enabled-profiles.conf
        - template: jinja
        - require:
            - nginx-config
            - profiles-uwsgi-service
        - listen_in:
            - service: nginx-server-service

profiles-syslog-ng:
    file.managed:
        - name: /etc/syslog-ng/conf.d/profiles.conf
        - source: salt://profiles/config/etc-syslog-ng-conf.d-profiles.conf
        - template: jinja
        - require:
            - pkg: syslog-ng
            - profiles-logs
        - listen_in:
            - service: syslog-ng

profiles-logrotate:
    file.managed:
        - name: /etc/logrotate.d/profiles
        - source: salt://profiles/config/etc-logrotate.d-profiles
        - template: jinja
        - require:
            - profiles-logs

{% if pillar.elife.env in ['dev', 'ci'] %}
profiles-topic-create:
    cmd.run:
        - name: aws --endpoint-url=http://localhost:4100 sns create-topic --name=profiles--{{ pillar.elife.env }}
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - goaws
            - aws-credentials-deploy-user
{% endif %}
