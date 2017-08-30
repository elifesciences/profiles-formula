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
        - require:
            - composer

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

profiles-config:
    file.managed:
        - name: /srv/profiles/app.cfg
        - source: salt://profiles/config/srv-profiles-app.cfg
        - template: jinja
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - require: 
            - profiles-composer-install

profiles-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/profiles.conf
        - source: salt://profiles/config/etc-nginx-sites-enabled-profiles.conf
        - template: jinja
        - require:
            - nginx-config
            - profiles-config
        - listen_in:
            - service: nginx-server-service
            - service: php-fpm
