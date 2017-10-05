orcid-dummy-repository-reset: 
    # to avoid
    # stderr: fatal: could not set upstream of HEAD to origin/master when it does not point to any branch.
    cmd.run:
        - name: cd /srv/orcid-dummy && git checkout master
        - user: {{ pillar.elife.deploy_user.username }}
        - onlyif:
            - test -d /srv/orcid-dummy

orcid-dummy-repository:
    builder.git_latest:
        - name: git@github.com:elifesciences/orcid-dummy.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: master
        - target: /srv/orcid-dummy/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True
        - require:
            - orcid-dummy-repository-reset

    file.directory:
        - name: /srv/orcid-dummy
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: orcid-dummy-repository

    cmd.run:
        - name: ./pin.sh $(cat {{ pillar.profiles.orcid_dummy.pinned_revision_file}})
        - cwd: /srv/orcid-dummy
        - user: {{ pillar.elife.deploy_user.username }}
        - require:
            - file: orcid-dummy-repository

orcid-dummy-composer-install:
    cmd.run:
        {% if pillar.elife.env != 'dev' %}
        - name: composer --no-interaction install --no-suggest --classmap-authoritative
        {% else %}
        - name: composer --no-interaction install --no-suggest
        {% endif %}
        - cwd: /srv/orcid-dummy/
        - user: {{ pillar.elife.deploy_user.username }}
        - env:
          - COMPOSER_DISCARD_CHANGES: 'true'
        - require:
            - orcid-dummy-repository
            - composer

orcid-dummy-nginx-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/orcid-dummy.conf
        - source: salt://profiles/config/etc-nginx-sites-enabled-orcid-dummy.conf
        - require: 
            - orcid-dummy-composer-install
        - listen_in:
            - service: nginx-server-service
            - service: php-fpm
