profiles-db-user:
    postgres_user.present:
        - name: {{ pillar.profiles.db.username }}
        - encrypted: True
        - password: {{ pillar.profiles.db.password }}
        - refresh_password: True
        - createdb: True
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}
        - require:
            - postgresql-ready

profiles-db:
    postgres_database.present:
        - owner: {{ pillar.profiles.db.username }}
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - name: {{ salt['elife.cfg']('project.rds_dbname') }}
        - db_user: {{ salt['elife.cfg']('project.rds_username') }}
        - db_password: {{ salt['elife.cfg']('project.rds_password') }}
        - db_host: {{ salt['elife.cfg']('cfn.outputs.RDSHost') }}
        - db_port: {{ salt['elife.cfg']('cfn.outputs.RDSPort') }}
        {% else %}
        # local psql
        - name: {{ pillar.profiles.db.name }}
        - db_user: {{ pillar.elife.db_root.username }}
        - db_password: {{ pillar.elife.db_root.password }}
        {% endif %}
        - require:
            - profiles-db-user

    cmd.run:
        - owner: {{ pillar.profiles.db.username }}
        - name: public
        {% if salt['elife.cfg']('cfn.outputs.RDSHost') %}
        # remote psql
        - name: |
            psql -h {{ salt['elife.cfg']('cfn.outputs.RDSHost') }} -p {{ salt['elife.cfg']('cfn.outputs.RDSPort') }} --no-password {{ salt['elife.cfg']('project.rds_dbname') }} {{ salt['elife.cfg']('project.rds_username') }} -c 'ALTER SCHEMA public OWNER TO {{ pillar.profiles.db.username }}'
        - env:
            - PGPASSWORD: {{ salt['elife.cfg']('project.rds_password') }}
        {% else %}
        # local psql
        - name: |
            psql --no-password {{ pillar.profiles.db.name}} {{ pillar.elife.db_root.username }} -c 'ALTER SCHEMA public OWNER TO {{ pillar.profiles.db.username }}'
        - env:
            - PGPASSWORD: {{ pillar.elife.db_root.password }}
        {% endif %}
        - require:
            - postgres_database: profiles-db

profiles-db-possible-cleanup:
    cmd.run:
{% if pillar.elife.env in ['dev', 'ci'] %}
        # no RDS supported
        - name: |
            psql --no-password {{ pillar.profiles.db.name}} {{ pillar.profiles.db.username }} -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
        - env:
            - PGPASSWORD: {{ pillar.profiles.db.password }}
        - require:
            - profiles-db
{% else %}
        - name: echo Nothing to do
{% endif %}

