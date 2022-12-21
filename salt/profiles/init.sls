profiles-folder:
    file.directory:
        - name: /srv/profiles
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}

    # deprecated: remove once all hosts are cleaned up
    cmd.run:
        - name: |
            rm -rf adr
            rm -f .adr-dir
            rm -f app.cfg.dist
            rm -rf build
            rm -f clients.yaml.dist
            rm -rf config/
            rm -f .coveragerc
            rm -f dev.env
            rm -f docker-compose*.yml
            rm -f Dockerfile*
            rm -f .dockerignore
            rm -f .env
            rm -f .flake8
            rm -rf .git
            rm -f .gitignore
            rm -f install.sh
            rm -f Jenkinsfile*
            rm -f LICENSE
            rm -f manage.py
            rm -rf migrations
            rm -f orcid-dummy.sha1
            rm -rf profiles
            rm -f project_tests.sh
            rm -f .pylintrc
            rm -f README.md
            rm -f requirements*.txt
            rm -f smoke_tests*.sh
            rm -rf test
            rm -f update-orcid-dummy.sh
            rm -rf venv
            rm -f wait_for_port
        - cwd: /srv/profiles
        - runas: {{ pillar.elife.deploy_user.username }}

profiles-logs:
    file.directory:
        - name: /srv/profiles/var/logs/
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - makedirs: True
        - dir_mode: 775
        - require:
            - profiles-folder

    # the g+s flag once made sure that new files and directories 
    # created inside by any user had the www-data group
    # deprecated: remove once not needed anywhere
    cmd.run:
        - name: chmod -R g-s /srv/profiles/var/logs
        - require:
            - file: profiles-folder

profiles-app-config:
    file.managed:
        - name: /srv/profiles/app.cfg
        - source: salt://profiles/config/srv-profiles-app.cfg
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require: 
            - profiles-folder
            - profiles-logs

profiles-clients-config:
    file.managed:
        - name: /srv/profiles/clients.yaml
        - source: salt://profiles/config/srv-profiles-clients.yaml
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-folder

profiles-uwsgi-config:
    file.managed:
        - name: /srv/profiles/uwsgi.ini
        - source: salt://profiles/config/srv-profiles-uwsgi.ini
        - template: jinja
        - require:
            - profiles-folder

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

orcid-dummy-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/orcid-dummy.conf
        - source: salt://profiles/config/etc-nginx-sites-enabled-orcid-dummy.conf
        - template: jinja
        - listen_in:
            - service: nginx-server-service

profiles-docker-containers:
    cmd.run:
        - name: /usr/local/bin/docker-compose up --force-recreate -d
        - runas: {{ pillar.elife.deploy_user.username }}
        - cwd: /home/{{ pillar.elife.deploy_user.username }}/profiles
        - require:
            - docker-ready
            - postgresql-ready
            - orcid-dummy-nginx-vhost
            - profiles-docker-compose-.env
            - profiles-containers-env
            - profiles-docker-compose-yml

profiles-migrate:
    cmd.run:
        - name: docker wait profiles_migrate_1
        - runas: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-docker-containers

integration-smoke-tests:
    file.managed:
        - name: /srv/profiles/smoke_tests.sh
        - source: salt://profiles/config/srv-profiles-smoke_tests.sh
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - mode: 755
        - require: 
            - profiles-folder
