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


profiles-install:
    cmd.run:
        - name: ./install.sh
        - cwd: /srv/profiles/
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-repository

profiles-app-config:
    file.managed:
        - name: /srv/profiles/app.cfg
        - source: salt://profiles/config/srv-profiles-app.cfg
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require: 
            - profiles-install

profiles-clients-config:
    file.managed:
        - name: /srv/profiles/clients.yaml
        - source: salt://profiles/config/srv-profiles-clients.yaml
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require:
            - profiles-install

profiles-uwsgi-config:
    file.managed:
        - name: /srv/profiles/uwsgi.ini
        - source: salt://profiles/config/srv-profiles-uwsgi.ini
        - template: jinja
        - require:
            - profiles-install

profiles-uwsgi-service:
    file.managed:
        - name: /etc/init/uwsgi-profiles.conf
        - source: salt://profiles/config/etc-init-uwsgi-profiles.conf
        - template: jinja
        - require:
            - profiles-install
            - profiles-app-config
            - profiles-clients-config
            - profiles-uwsgi-config

    service.running:
        - name: uwsgi-profiles
        - enable: True
        - reload: True
        - require:
            - file: profiles-uwsgi-service
        - watch:
            - profiles-install

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

