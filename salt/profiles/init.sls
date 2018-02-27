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
        - require:
            - builder: profiles-repository

profiles-logs:
    file.directory:
        - name: /srv/profiles/var/logs/
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - dir_mode: 775
        - require:
            - profiles-repository

    # the g+s flag once made sure that new files and directories 
    # created inside by any user had the www-data group
    # deprecated: remove once not needed anywhere
    cmd.run:
        - name: chmod -R g-s /srv/profiles/var/logs
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

profiles-uwsgi-config:
    file.managed:
        - name: /srv/profiles/uwsgi.ini
        - source: salt://profiles/config/srv-profiles-uwsgi.ini
        - template: jinja
        - require:
            - profiles-repository

profiles-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/profiles.conf
        - source: salt://profiles/config/etc-nginx-sites-enabled-profiles.conf
        - template: jinja
        - require:
            - nginx-config
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

profiles-docker-compose-folder:
    file.directory:
        - name: /home/{{ pillar.elife.deploy_user.username }}/profiles/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - deploy-user

# variable for docker-compose
profiles-docker-compose-.env:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/profiles/.env
        - source: salt://profiles/config/home-deployuser-profiles-.env
        - makedirs: True
        - template: jinja
        - require:
            - profiles-docker-compose-folder

# variables for the containers
profiles-containers-env:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/profiles/containers.env
        - source: salt://profiles/config/home-deployuser-profiles-containers.env
        - template: jinja
        - require:
            - profiles-docker-compose-folder

profiles-docker-compose-yml:
    file.managed:
        - name: /home/{{ pillar.elife.deploy_user.username }}/profiles/docker-compose.yml
        - source: salt://profiles/config/home-deployuser-profiles-docker-compose.yml
        - template: jinja
        - require:
            - profiles-docker-compose-folder

profiles-docker-containers:
    cmd.run:
        - name: /usr/local/bin/docker-compose up --force-recreate -d
        - user: {{ pillar.elife.deploy_user.username }}
        - cwd: /home/{{ pillar.elife.deploy_user.username }}/profiles
        - require:
            - profiles-docker-compose-.env
            - profiles-containers-env
            - profiles-docker-compose-yml

profiles-migrate:
    cmd.run:
        - name: docker wait profiles_migrate_1
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-docker-containers
