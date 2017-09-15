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
